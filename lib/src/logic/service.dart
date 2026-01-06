import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/utils/formatters.dart';

/// Sophisticated API Logger service with in-memory storage and viewer support
class Monitor {
  Monitor._();

  // Singleton instance
  static final Monitor _instance = Monitor._();
  static Monitor get instance => _instance;

  /// Enable API logging for debugging (console output)
  static late bool _enableApiConsoleLogs;

  /// Enable in-memory log storage (for API Logs Viewer)
  static late bool _enableApiLogStorage;

  // Global navigator key for opening logs from anywhere
  static GlobalKey<NavigatorState>? navigatorKey;

  // In-memory log storage - Map for O(1) lookup by ID
  final Map<String, LogEntry> _logsById = {};
  final List<String> _logOrder = []; // Maintain insertion order
  static const int _maxLogs = 500;

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
    if (!_enableApiLogStorage) return;

    _logsById[entry.id] = entry;
    _logOrder.add(entry.id);

    // Trim logs if exceeding max
    while (_logOrder.length > _maxLogs) {
      final oldestId = _logOrder.removeAt(0);
      _logsById.remove(oldestId);
    }

    _notifyListeners();
  }

  /// Update an existing log entry
  void _updateLog(String id, LogEntry entry) {
    if (!_enableApiLogStorage) return;
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
    final id = _generateId('HTTP');
    final redactedHeaders = headers != null ? redactAuth(headers) : null;

    final entry = HttpLogEntry(
      id: id,
      timestamp: DateTime.now(),
      method: method,
      url: uri.toString(),
      state: HttpLogState.pending,
      requestHeaders: redactedHeaders,
      requestBody: body,
      requestSize:
          bodyBytes ?? (body != null ? utf8.encode(body).length : null),
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
    final existing = _instance._logsById[id];
    if (existing == null || existing is! HttpLogEntry) {
      error('Cannot complete request: ID $id not found or not an HTTP entry');
      return;
    }

    final state = statusCode >= 200 && statusCode < 400
        ? HttpLogState.success
        : HttpLogState.error;

    final updated = existing.complete(
      state: state,
      statusCode: statusCode,
      duration: duration,
      responseHeaders: responseHeaders,
      responseBody: responseBody,
      responseSize:
          responseSize ??
          (responseBody != null ? utf8.encode(responseBody).length : null),
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
  // Initialization
  // ═══════════════════════════════════════════════════════════════════════════

  static void init({
    required String baseUrl,
    required String appVersion,
    bool enableApiLogStorage = true,
    bool enableApiConsoleLogs = true,
  }) {
    _enableApiConsoleLogs = enableApiConsoleLogs;
    _enableApiLogStorage = enableApiLogStorage;

    // Store system init log
    _instance._addLog(
      MessageLogEntry(
        id: _generateId('INIT'),
        timestamp: DateTime.now(),
        level: MessageLevel.info,
        message:
            'API Service Initialized\n'
            'Base URL: $baseUrl\n'
            'App Version: $appVersion\n'
            'Console Logs: ${_enableApiConsoleLogs ? 'Enabled' : 'Disabled'}\n'
            'Log Storage: ${_enableApiLogStorage ? 'Enabled' : 'Disabled'}',
      ),
    );

    final timestamp = DateTime.now().toIso8601String();
    final separator = '=' * 80;

    final lines = [
      '+$separator+',
      '| [SYSTEM] $timestamp',
      '| API Service Initialized',
      '| Base URL: $baseUrl',
      '| App Version: $appVersion',
      '| Console Logs: ${_enableApiConsoleLogs ? 'Enabled' : 'Disabled'}',
      '| Log Storage: ${_enableApiLogStorage ? 'Enabled' : 'Disabled'}',
      '+$separator+',
    ];

    if (_shouldUseColors) {
      debugPrint(lines.map((line) => '$_white$line$_reset').join('\n'));
    } else {
      debugPrint(lines.join('\n'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Console Output
  // ═══════════════════════════════════════════════════════════════════════════

  static void _printRequest(HttpLogEntry entry) {
    if (!_enableApiConsoleLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    final separator = '=' * 80;

    final lines = [
      '+$separator+',
      '| [REQUEST] $timestamp',
      '| +- REQUEST [${entry.id}] ------------------------------------',
      '| | ${entry.method} ${entry.url}',
      '| | Headers:',
      if (entry.requestHeaders != null)
        ...prettyJson(
          entry.requestHeaders!,
        ).split('\n').map((line) => '| |   $line'),
      if (entry.requestBody != null && entry.requestBody!.isNotEmpty) ...[
        '| | Body (${formatBytes(entry.requestSize ?? utf8.encode(entry.requestBody!).length)}):',
        ...truncateIfNeeded(
          entry.requestBody!,
        ).split('\n').map((line) => '| |   $line'),
      ],
      '| +------------------------------------------------------------',
      '+$separator+',
    ];

    if (_shouldUseColors) {
      debugPrint(lines.map((line) => '$_cyan$line$_reset').join('\n'));
    } else {
      debugPrint(lines.join('\n'));
    }
  }

  static void _printResponse(HttpLogEntry entry) {
    if (!_enableApiConsoleLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    final separator = '=' * 80;

    String statusCategory;
    String color;
    String statusIcon;
    final status = entry.statusCode ?? 0;

    if (status >= 200 && status < 300) {
      statusCategory = 'SUCCESS';
      color = _green;
      statusIcon = '+';
    } else if (status == 204) {
      statusCategory = 'NO CONTENT';
      color = _blue;
      statusIcon = 'o';
    } else if (status >= 400 && status < 500) {
      statusCategory = 'CLIENT ERROR';
      color = _yellow;
      statusIcon = '!';
    } else {
      statusCategory = 'SERVER ERROR';
      color = _red;
      statusIcon = 'x';
    }

    final lines = [
      '+$separator+',
      '| [RESPONSE] $timestamp',
      '| +- RESPONSE [${entry.id}] -----------------------------------',
      '| | URL: ${entry.url}',
      '| | Status: $statusIcon $status ($statusCategory) | ${entry.durationText} | ${entry.responseSizeText}',
      if (entry.responseBody != null && entry.responseBody!.isNotEmpty) ...[
        '| | Response:',
        ...truncateIfNeeded(
          entry.prettyResponseBody ?? entry.responseBody!,
        ).split('\n').map((line) => '| |   $line'),
      ],
      '| +------------------------------------------------------------',
      '+$separator+',
    ];

    if (_shouldUseColors) {
      debugPrint(lines.map((line) => '$color$line$_reset').join('\n'));
    } else {
      debugPrint(lines.join('\n'));
    }
  }

  static void _printError(HttpLogEntry entry) {
    if (!_enableApiConsoleLogs) return;

    final timestamp = DateTime.now().toIso8601String();
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
      debugPrint(lines.map((line) => '$_red$line$_reset').join('\n'));
    } else {
      debugPrint(lines.join('\n'));
    }
  }

  static void _printMessage(MessageLogEntry entry) {
    if (!_enableApiConsoleLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    final separator = '-' * 80;

    String color;
    switch (entry.level) {
      case MessageLevel.info:
        color = _blue;
      case MessageLevel.warning:
        color = _yellow;
      case MessageLevel.error:
        color = _red;
    }

    if (_shouldUseColors) {
      debugPrint(
        '\n$color+$separator+$_reset\n'
        '$color| [${entry.level.label}] $timestamp$_reset\n'
        '$color| ${entry.message}$_reset\n'
        '$color+$separator+$_reset',
      );
    } else {
      debugPrint(
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
