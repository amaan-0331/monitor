import 'dart:async' show Stream, StreamController;
import 'dart:convert' show utf8, json;
import 'dart:io' show Platform;
import 'dart:math' show Random;
import 'dart:developer' as dev show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/models/config.dart';
import 'package:monitor/src/utils/formatters.dart';

/// Sophisticated API Logger service with in-memory storage and viewer support
class Monitor {
  Monitor._();

  // Singleton instance
  static final Monitor _instance = Monitor._();
  static Monitor get instance => _instance;

  /// Current configuration
  static late MonitorConfig _config;
  static MonitorConfig get config => _config;

  // Global navigator key for opening logs from anywhere
  static GlobalKey<NavigatorState>? navigatorKey;

  // In-memory log storage - Map for O(1) lookup by ID
  final Map<String, LogEntry> _logsById = {};
  final List<String> _logOrder = []; // Maintain insertion order

  // Stream controller for real-time updates
  final _logStreamController = StreamController<List<LogEntry>>.broadcast();
  Stream<List<LogEntry>> get logStream => _logStreamController.stream;

  // Console color codes
  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _cyan = '\x1B[36m';
  static const _white = '\x1B[37m';

  /// Get all logs (newest first)
  List<LogEntry> get logs {
    return List.unmodifiable(
      _logOrder.reversed.map((id) => _logsById[id]!).toList(),
    );
  }

  /// Get only HTTP logs
  List<HttpLogEntry> get httpLogs {
    return logs.whereType<HttpLogEntry>().toList();
  }

  /// Get only message logs
  List<MessageLogEntry> get messageLogs {
    return logs.whereType<MessageLogEntry>().toList();
  }

  /// Get logs filtered by HTTP state
  List<HttpLogEntry> getLogsByState(HttpLogState state) =>
      httpLogs.where((log) => log.state == state).toList();

  /// Get logs filtered by method
  List<HttpLogEntry> getLogsByMethod(String method) =>
      httpLogs.where((log) => log.method == method).toList();

  /// Get error logs only
  List<LogEntry> get errorLogs => logs.where((log) {
    return switch (log) {
      HttpLogEntry entry => entry.isError,
      MessageLogEntry entry => entry.isError,
    };
  }).toList();

  /// Get success logs only
  List<HttpLogEntry> get successLogs =>
      httpLogs.where((log) => log.isSuccess).toList();

  /// Get pending logs only
  List<HttpLogEntry> get pendingLogs =>
      httpLogs.where((log) => log.isPending).toList();

  /// Search logs by URL or message
  List<LogEntry> search(String query) {
    final lowerQuery = query.toLowerCase();
    return logs.where((log) {
      return switch (log) {
        HttpLogEntry entry =>
          entry.url.toLowerCase().contains(lowerQuery) ||
              entry.method.toLowerCase().contains(lowerQuery),
        MessageLogEntry entry =>
          entry.message.toLowerCase().contains(lowerQuery) ||
              (entry.url?.toLowerCase().contains(lowerQuery) ?? false),
      };
    }).toList();
  }

  /// Clear all logs
  void clearLogs() {
    _logsById.clear();
    _logOrder.clear();
    _notifyListeners();
  }

  /// Add a log entry
  void _addLog(LogEntry entry) {
    if (!_config.enableLogStorage) return;

    _logsById[entry.id] = entry;
    _logOrder.add(entry.id);

    // Trim logs if exceeding max
    while (_logOrder.length > _config.maxLogs) {
      final oldestId = _logOrder.removeAt(0);
      _logsById.remove(oldestId);
    }

    _notifyListeners();
  }

  /// Update an existing log entry
  void _updateLog(String id, LogEntry entry) {
    if (!_config.enableLogStorage) return;
    if (!_logsById.containsKey(id)) return;

    _logsById[id] = entry;
    _notifyListeners();
  }

  void _notifyListeners() {
    _logStreamController.add(logs);
  }

  /// Generate unique ID for log entries
  static String _generateId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  // Check if we should use colors
  static bool get _shouldUseColors {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid ||
          Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux;
    } on Exception {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HTTP Request Lifecycle API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start tracking an HTTP request - returns the ID for later completion
  static String startRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
    int? bodyBytes,
  }) {
    final url = uri.toString();

    final id = _generateId('HTTP');

    // Redact headers
    final redactedHeaders = headers != null && _config.logRequestHeaders
        ? _redactHeaders(headers)
        : null;

    // Redact and truncate body
    String? processedBody;
    int? processedSize;
    if (body != null && _config.logRequestBody) {
      processedBody = _redactBody(body);
      processedSize = bodyBytes ?? utf8.encode(body).length;
      processedBody = _config.truncateIfNeeded(
        processedBody,
        _config.maxBodyLength,
      );
    }

    final entry = HttpLogEntry(
      id: id,
      timestamp: DateTime.now(),
      method: method,
      url: url,
      state: HttpLogState.pending,
      requestHeaders: redactedHeaders,
      requestBody: processedBody,
      requestSize: processedSize,
    );

    _instance._addLog(entry);
    _printRequest(entry);

    return id;
  }

  /// Complete an HTTP request with success response
  static void completeRequest({
    required String id,
    required int statusCode,
    required Duration duration,
    Map<String, String>? responseHeaders,
    String? responseBody,
    int? responseSize,
  }) {
    // Ignore filtered requests
    if (id.startsWith('HTTP-FILTERED')) return;

    final existing = _instance._logsById[id];
    if (existing == null || existing is! HttpLogEntry) {
      error('Cannot complete request: ID $id not found or not an HTTP entry');
      return;
    }

    final state = statusCode >= 200 && statusCode < 400
        ? HttpLogState.success
        : HttpLogState.error;

    // Redact headers
    final redactedHeaders =
        responseHeaders != null && _config.logResponseHeaders
        ? _redactHeaders(responseHeaders)
        : null;

    // Redact and truncate body
    String? processedBody;
    int? processedSize;
    if (responseBody != null && _config.logResponseBody) {
      processedBody = _redactBody(responseBody);
      processedSize = responseSize ?? utf8.encode(responseBody).length;
      processedBody = _config.truncateIfNeeded(
        processedBody,
        _config.maxBodyLength,
      );
    }

    final updated = existing.complete(
      state: state,
      statusCode: statusCode,
      duration: duration,
      responseHeaders: redactedHeaders,
      responseBody: processedBody,
      responseSize: processedSize,
    );

    _instance._updateLog(id, updated);
    _printResponse(updated);
  }

  /// Complete an HTTP request with error (network failure, exception)
  static void failRequest({
    required String id,
    required String errorMessage,
    Duration? duration,
    bool isTimeout = false,
  }) {
    // Ignore filtered requests
    if (id.startsWith('HTTP-FILTERED')) return;

    final existing = _instance._logsById[id];
    if (existing == null || existing is! HttpLogEntry) {
      error('Cannot fail request: ID $id not found or not an HTTP entry');
      return;
    }

    final updated = existing.complete(
      state: isTimeout ? HttpLogState.timeout : HttpLogState.error,
      duration: duration,
      errorMessage: errorMessage,
    );

    _instance._updateLog(id, updated);
    _printError(updated);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Message Logging API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log a message (info, warning, error)
  static void message(
    String msg, {
    MessageLevel level = MessageLevel.info,
    String? url,
  }) {
    final entry = MessageLogEntry(
      id: _generateId('MSG'),
      timestamp: DateTime.now(),
      level: level,
      message: msg,
      url: url,
    );

    _instance._addLog(entry);
    _printMessage(entry);
  }

  // Convenience methods
  static void info(String msg) => message(msg, level: MessageLevel.info);
  static void warning(String msg) => message(msg, level: MessageLevel.warning);
  static void error(String msg) => message(msg, level: MessageLevel.error);

  /// Cache hit (special info message with URL context)
  static void cacheHit({required String cacheKey}) {
    message('Cache hit - served from memory', url: cacheKey);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Privacy & Redaction
  // ═══════════════════════════════════════════════════════════════════════════

  /// Redact sensitive headers
  static Map<String, String> _redactHeaders(Map<String, String> headers) {
    final redacted = <String, String>{};

    for (final entry in headers.entries) {
      final keyLower = entry.key.toLowerCase();
      final shouldRedact = _config.headerRedactionKeys.any(
        (key) => keyLower.contains(key.toLowerCase()),
      );

      redacted[entry.key] = shouldRedact ? '***REDACTED***' : entry.value;
    }

    // Truncate if needed
    if (_config.maxHeaderLength != null) {
      final truncated = <String, String>{};
      for (final entry in redacted.entries) {
        truncated[entry.key] =
            _config.truncateIfNeeded(entry.value, _config.maxHeaderLength) ??
            entry.value;
      }
      return truncated;
    }

    return redacted;
  }

  /// Redact sensitive body fields (works with JSON)
  static String _redactBody(String body) {
    try {
      // Try to parse as JSON
      final decoded = json.decode(body);
      final redacted = _redactJsonObject(decoded);
      return prettyJson(redacted);
    } catch (_) {
      // Not JSON, return as-is
      return body;
    }
  }

  /// Recursively redact JSON object
  static dynamic _redactJsonObject(dynamic obj) {
    if (obj is Map) {
      final redacted = <String, dynamic>{};
      for (final entry in obj.entries) {
        final key = entry.key.toString();
        final keyLower = key.toLowerCase();
        final shouldRedact = _config.bodyRedactionKeys.any(
          (redactKey) => keyLower.contains(redactKey.toLowerCase()),
        );

        if (shouldRedact) {
          redacted[key] = '***REDACTED***';
        } else if (entry.value is Map || entry.value is List) {
          redacted[key] = _redactJsonObject(entry.value);
        } else {
          redacted[key] = entry.value;
        }
      }
      return redacted;
    } else if (obj is List) {
      return obj.map(_redactJsonObject).toList();
    }
    return obj;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Initialization
  // ═══════════════════════════════════════════════════════════════════════════

  static void init({MonitorConfig? config}) {
    _config = config ?? MonitorConfig();

    // Store system init log
    _instance._addLog(
      MessageLogEntry(
        id: _generateId('INIT'),
        timestamp: DateTime.now(),
        level: MessageLevel.info,
        message:
            'API Service Initialized\n'
            'Console Format: ${_config.consoleFormat.name}\n'
            'Log Storage: ${_config.enableLogStorage ? 'Enabled' : 'Disabled'}\n'
            'Max Logs: ${_config.maxLogs}',
      ),
    );

    if (!_config.consoleFormat.isEnabled) return;

    final timestamp = DateTime.now().toIso8601String();

    if (_config.consoleFormat == ConsoleLogFormat.simple) {
      final message =
          'ℹ API Service Initialized | '
          'Storage: ${_config.enableLogStorage ? 'On' : 'Off'} | '
          'MaxLogs: ${_config.maxLogs}';

      if (_shouldUseColors) {
        dev.log('$_white[$timestamp] $message$_reset');
      } else {
        dev.log('[$timestamp] $message');
      }
      return;
    }

    // verbose mode only below
    final separator = '=' * 80;

    final lines = [
      '+$separator+',
      '| [SYSTEM] $timestamp',
      '| API Service Initialized',
      '| Console Format: ${_config.consoleFormat.name}',
      '| Log Storage: ${_config.enableLogStorage ? 'Enabled' : 'Disabled'}',
      '| Max Logs: ${_config.maxLogs}',
      '+$separator+',
    ];

    if (_shouldUseColors) {
      dev.log(lines.map((line) => '$_white$line$_reset').join('\n'));
    } else {
      dev.log(lines.join('\n'));
    }
  }

  /// Update configuration at runtime
  static void updateConfig(MonitorConfig newConfig) {
    _config = newConfig;
    info('Monitor configuration updated');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Console Output
  // ═══════════════════════════════════════════════════════════════════════════

  static void _printRequest(HttpLogEntry entry) {
    if (!_config.consoleFormat.isEnabled) return;

    final timestamp = entry.timestamp.toIso8601String();

    if (_config.consoleFormat == ConsoleLogFormat.simple) {
      _printSimpleRequest(entry, timestamp);
      return;
    }

    // Verbose format
    final separator = '=' * 80;

    final lines = [
      '+$separator+',
      '| [REQUEST] $timestamp',
      '| +- REQUEST [${entry.id}] ------------------------------------',
      '| | ${entry.method} ${entry.url}',
      if (entry.requestHeaders != null && entry.requestHeaders!.isNotEmpty) ...[
        '| | Headers:',
        ...prettyJson(
          entry.requestHeaders!,
        ).split('\n').map((line) => '| |   $line'),
      ],
      if (entry.requestBody != null && entry.requestBody!.isNotEmpty) ...[
        '| | Body (${formatBytes(entry.requestSize ?? 0)}):',
        ...entry.requestBody!.split('\n').map((line) => '| |   $line'),
      ],
      '| +------------------------------------------------------------',
      '+$separator+',
    ];

    if (_shouldUseColors) {
      dev.log(lines.map((line) => '$_cyan$line$_reset').join('\n'));
    } else {
      dev.log(lines.join('\n'));
    }
  }

  static void _printSimpleRequest(HttpLogEntry entry, String timestamp) {
    final size = entry.requestSize != null
        ? formatBytes(entry.requestSize!)
        : '';
    final message = '→ ${entry.method} ${entry.url} $size';

    if (_shouldUseColors) {
      dev.log('$_cyan[$timestamp] $message$_reset');
    } else {
      dev.log('[$timestamp] $message');
    }
  }

  static void _printResponse(HttpLogEntry entry) {
    if (!_config.consoleFormat.isEnabled) return;

    final timestamp = DateTime.now().toIso8601String();

    if (_config.consoleFormat == ConsoleLogFormat.simple) {
      _printSimpleResponse(entry, timestamp);
      return;
    }

    // Verbose format
    final separator = '=' * 80;

    String statusCategory;
    String color;
    String statusIcon;
    final status = entry.statusCode ?? 0;

    if (status >= 200 && status < 300) {
      statusCategory = 'SUCCESS';
      color = _green;
      statusIcon = '✓';
    } else if (status == 204) {
      statusCategory = 'NO CONTENT';
      color = _blue;
      statusIcon = 'ø';
    } else if (status >= 400 && status < 500) {
      statusCategory = 'CLIENT ERROR';
      color = _yellow;
      statusIcon = '!';
    } else {
      statusCategory = 'SERVER ERROR';
      color = _red;
      statusIcon = '✗';
    }

    final lines = [
      '+$separator+',
      '| [RESPONSE] $timestamp',
      '| +- RESPONSE [${entry.id}] -----------------------------------',
      '| | URL: ${entry.url}',
      '| | Status: $statusIcon $status ($statusCategory) | ${entry.durationText} | ${entry.responseSizeText}',
      if (entry.responseBody != null && entry.responseBody!.isNotEmpty) ...[
        '| | Response:',
        ...entry.responseBody!.split('\n').map((line) => '| |   $line'),
      ],
      '| +------------------------------------------------------------',
      '+$separator+',
    ];

    if (_shouldUseColors) {
      dev.log(lines.map((line) => '$color$line$_reset').join('\n'));
    } else {
      dev.log(lines.join('\n'));
    }
  }

  static void _printSimpleResponse(HttpLogEntry entry, String timestamp) {
    final status = entry.statusCode ?? 0;
    final color = status >= 200 && status < 400 ? _green : _red;
    final icon = status >= 200 && status < 400 ? '✓' : '✗';
    final message =
        '← $icon $status ${entry.method} ${entry.url} ${entry.durationText} ${entry.responseSizeText}';

    if (_shouldUseColors) {
      dev.log('$color[$timestamp] $message$_reset');
    } else {
      dev.log('[$timestamp] $message');
    }
  }

  static void _printError(HttpLogEntry entry) {
    if (!_config.consoleFormat.isEnabled) return;

    final timestamp = DateTime.now().toIso8601String();

    if (_config.consoleFormat == ConsoleLogFormat.simple) {
      final message =
          '✗ ERROR ${entry.method} ${entry.url} - ${entry.errorMessage ?? entry.state.label}';
      if (_shouldUseColors) {
        dev.log('$_red[$timestamp] $message$_reset');
      } else {
        dev.log('[$timestamp] $message');
      }
      return;
    }

    // Verbose format
    final separator = '=' * 80;

    final lines = [
      '+$separator+',
      '| [ERROR] $timestamp',
      '| +- ERROR [${entry.id}] --------------------------------------',
      '| | URL: ${entry.url}',
      '| | State: ${entry.state.label}',
      if (entry.errorMessage != null) '| | Error: ${entry.errorMessage}',
      if (entry.duration != null) '| | Duration: ${entry.durationText}',
      '| +------------------------------------------------------------',
      '+$separator+',
    ];

    if (_shouldUseColors) {
      dev.log(lines.map((line) => '$_red$line$_reset').join('\n'));
    } else {
      dev.log(lines.join('\n'));
    }
  }

  static void _printMessage(MessageLogEntry entry) {
    if (!_config.consoleFormat.isEnabled) return;

    final timestamp = entry.timestamp.toIso8601String();

    String color;
    String icon;
    switch (entry.level) {
      case MessageLevel.info:
        color = _blue;
        icon = 'ℹ';
      case MessageLevel.warning:
        color = _yellow;
        icon = '⚠';
      case MessageLevel.error:
        color = _red;
        icon = '✗';
    }

    if (_config.consoleFormat == ConsoleLogFormat.simple) {
      final message = '$icon ${entry.message}';
      if (_shouldUseColors) {
        dev.log('$color[$timestamp] $message$_reset');
      } else {
        dev.log('[$timestamp] $message');
      }
      return;
    }

    // Verbose format
    final separator = '-' * 80;

    if (_shouldUseColors) {
      dev.log(
        '\n$color+$separator+$_reset\n'
        '$color| [${entry.level.label}] $timestamp$_reset\n'
        '$color| ${entry.message}$_reset\n'
        '$color+$separator+$_reset',
      );
    } else {
      dev.log(
        '\n+$separator+\n'
        '| [${entry.level.label}] $timestamp\n'
        '| ${entry.message}\n'
        '+$separator+',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _logStreamController.close();
  }
}
