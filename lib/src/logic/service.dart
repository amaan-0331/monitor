import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:monitor/src/models/api_log_entry.dart';

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

  // In-memory log storage
  final List<ApiLogEntry> _logs = [];
  static const int _maxLogs = 500;

  // Stream controller for real-time updates
  final _logStreamController = StreamController<List<ApiLogEntry>>.broadcast();
  Stream<List<ApiLogEntry>> get logStream => _logStreamController.stream;

  // Console color codes
  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _magenta = '\x1B[35m';
  static const _cyan = '\x1B[36m';
  static const _white = '\x1B[37m';

  /// Get all logs (newest first)
  List<ApiLogEntry> get logs => List.unmodifiable(_logs.reversed.toList());

  /// Get logs filtered by type
  List<ApiLogEntry> getLogsByType(ApiLogType type) =>
      logs.where((log) => log.type == type).toList();

  /// Get logs filtered by method
  List<ApiLogEntry> getLogsByMethod(String method) =>
      logs.where((log) => log.method == method).toList();

  /// Get error logs only
  List<ApiLogEntry> get errorLogs => logs.where((log) => log.isError).toList();

  /// Get success logs only
  List<ApiLogEntry> get successLogs =>
      logs.where((log) => log.isSuccess).toList();

  /// Search logs by URL or message
  List<ApiLogEntry> search(String query) {
    final lowerQuery = query.toLowerCase();
    return logs.where((log) {
      final url = log.url?.toLowerCase() ?? '';
      final message = log.message?.toLowerCase() ?? '';
      final method = log.method?.toLowerCase() ?? '';
      return url.contains(lowerQuery) ||
          message.contains(lowerQuery) ||
          method.contains(lowerQuery);
    }).toList();
  }

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
    _notifyListeners();
  }

  /// Add a log entry
  void _addLog(ApiLogEntry entry) {
    if (!_enableApiLogStorage) return;

    _logs.add(entry);

    // Trim logs if exceeding max
    while (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

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

  static void _log(
    String message, {
    String level = 'INFO',
    String color = _white,
    ApiLogType type = ApiLogType.info,
  }) {
    // Store in memory
    _instance._addLog(
      ApiLogEntry(
        id: _generateId('LOG'),
        timestamp: DateTime.now(),
        type: type,
        message: message,
      ),
    );

    if (!_enableApiConsoleLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    final separator = '─' * 80;

    if (_shouldUseColors) {
      debugPrint(
        '\n$color┌$separator┐$_reset\n'
        '$color│ [$level] $timestamp$_reset\n'
        '$color│ $message$_reset\n'
        '$color└$separator┘$_reset',
      );
    } else {
      debugPrint(
        '\n┌$separator┐\n'
        '│ [$level] $timestamp\n'
        '│ $message\n'
        '└$separator┘',
      );
    }
  }

  static void info(String msg) => _log(msg, color: _blue);
  static void success(String msg) =>
      _log(msg, level: 'SUCCESS', color: _green, type: ApiLogType.success);
  static void warning(String msg) =>
      _log(msg, level: 'WARNING', color: _yellow, type: ApiLogType.warning);
  static void error(String msg) =>
      _log(msg, level: 'ERROR', color: _red, type: ApiLogType.error);
  static void request(String msg) =>
      _log(msg, level: 'REQUEST', color: _cyan, type: ApiLogType.request);
  static void response(String msg) =>
      _log(msg, level: 'RESPONSE', color: _magenta, type: ApiLogType.response);
  static void cache(String msg) =>
      _log(msg, level: 'CACHE', color: _yellow, type: ApiLogType.cache);
  static void auth(String msg) =>
      _log(msg, level: 'AUTH', color: _green, type: ApiLogType.auth);

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
      ApiLogEntry(
        id: _generateId('INIT'),
        timestamp: DateTime.now(),
        type: ApiLogType.system,
        message:
            'API Service Initialized\n'
            'Base URL: $baseUrl\n'
            'App Version: $appVersion\n'
            'Console Logs: ${_enableApiConsoleLogs ? 'Enabled' : 'Disabled'}\n'
            'Log Storage: ${_enableApiLogStorage ? 'Enabled' : 'Disabled'}',
      ),
    );

    final timestamp = DateTime.now().toIso8601String();
    final separator = '═' * 80;

    final lines = [
      '┌$separator┐',
      '│ [SYSTEM] $timestamp',
      '│ API Service Initialized',
      '│ Base URL: $baseUrl',
      '│ App Version: $appVersion',
      '│ Console Logs: ${_enableApiConsoleLogs ? 'Enabled' : 'Disabled'}',
      '│ Log Storage: ${_enableApiLogStorage ? 'Enabled' : 'Disabled'}',
      '└$separator┘',
    ];

    if (_shouldUseColors) {
      debugPrint(lines.map((line) => '$_white$line$_reset').join('\n'));
    } else {
      debugPrint(lines.join('\n'));
    }
  }

  /// Log detailed request information
  static void requestDetail({
    required String id,
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
    int? bodyBytes,
  }) {
    final redactedHeaders = _redactAuth(headers);

    // Store in memory
    _instance._addLog(
      ApiLogEntry(
        id: id,
        timestamp: DateTime.now(),
        type: ApiLogType.request,
        method: method,
        url: uri.toString(),
        requestHeaders: redactedHeaders,
        requestBody: body,
        size: bodyBytes ?? (body != null ? utf8.encode(body).length : null),
      ),
    );

    if (!_enableApiConsoleLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    final separator = '═' * 80;

    final lines = [
      '┌$separator┐',
      '│ [REQUEST] $timestamp',
      '│ ┌─ REQUEST [$id] ─────────────────────────────────────────────────',
      '│ │ $method $uri',
      '│ │ Headers:',
      ...prettyJson(redactedHeaders).split('\n').map((line) => '│ │   $line'),
      if (body != null && body.isNotEmpty) ...[
        '│ │ Body (${_formatBytes(bodyBytes ?? utf8.encode(body).length)}):',
        ..._truncateIfNeeded(body).split('\n').map((line) => '│ │   $line'),
      ],
      '│ └────────────────────────────────────────────────────────────────',
      '└$separator┘',
    ];

    if (_shouldUseColors) {
      debugPrint(lines.map((line) => '$_cyan$line$_reset').join('\n'));
    } else {
      debugPrint(lines.join('\n'));
    }
  }

  /// Log detailed response information
  static void responseDetail({
    required String id,
    required Uri uri,
    required int status,
    required Duration elapsed,
    required String bodyRaw,
  }) {
    final size = utf8.encode(bodyRaw).length;

    // Store in memory
    _instance._addLog(
      ApiLogEntry(
        id: '$id-response',
        timestamp: DateTime.now(),
        type: ApiLogType.response,
        method: 'RESPONSE',
        url: uri.toString(),
        statusCode: status,
        duration: elapsed,
        responseBody: bodyRaw,
        size: size,
      ),
    );

    if (!_enableApiConsoleLogs) return;

    final decoded = _safeDecode(bodyRaw);
    final pretty = prettyJson(decoded);
    final sizeStr = _formatBytes(size);
    final timestamp = DateTime.now().toIso8601String();
    final separator = '═' * 80;

    String statusCategory;
    String color;
    String statusIcon;
    if (status >= 200 && status < 300) {
      statusCategory = 'SUCCESS';
      color = _green;
      statusIcon = '✓';
    } else if (status == 204) {
      statusCategory = 'NO CONTENT';
      color = _blue;
      statusIcon = '○';
    } else if (status >= 400 && status < 500) {
      statusCategory = 'CLIENT ERROR';
      color = _yellow;
      statusIcon = '⚠';
    } else {
      statusCategory = 'SERVER ERROR';
      color = _red;
      statusIcon = '✗';
    }

    final lines = [
      '┌$separator┐',
      '│ [RESPONSE] $timestamp',
      '│ ┌─ RESPONSE [$id] ───────────────────────────────────────────────',
      '│ │ URL: $uri',
      '│ │ Status: $statusIcon $status ($statusCategory) │ ${elapsed.inMilliseconds}ms │ $sizeStr',
      if (bodyRaw.isNotEmpty) ...[
        '│ │ Response:',
        ..._truncateIfNeeded(pretty).split('\n').map((line) => '│ │   $line'),
      ],
      '│ └────────────────────────────────────────────────────────────────',
      '└$separator┘',
    ];

    if (_shouldUseColors) {
      debugPrint(lines.map((line) => '$color$line$_reset').join('\n'));
    } else {
      debugPrint(lines.join('\n'));
    }
  }

  /// Log detailed cache hit information
  static void cacheHit({required String id, required String cacheKey}) {
    // Store in memory
    _instance._addLog(
      ApiLogEntry(
        id: id,
        timestamp: DateTime.now(),
        type: ApiLogType.cacheHit,
        url: cacheKey,
        message: 'Cache hit - served from memory',
      ),
    );

    if (!_enableApiConsoleLogs) return;

    final timestamp = DateTime.now().toIso8601String();
    final separator = '═' * 80;

    final lines = [
      '┌$separator┐',
      '│ [CACHE HIT] $timestamp',
      '│ ┌─ CACHE HIT [$id] ──────────────────────────────────────────────',
      '│ │ Cache hit - served from memory',
      '│ │ Key: $cacheKey',
      '│ │ Ultra fast response - no network call needed!',
      '│ └────────────────────────────────────────────────────────────────',
      '└$separator┘',
    ];

    if (_shouldUseColors) {
      debugPrint(lines.map((line) => '$_yellow$line$_reset').join('\n'));
    } else {
      debugPrint(lines.join('\n'));
    }
  }

  // Utility methods
  static String prettyJson(dynamic jsonObject) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObject);
    } on Exception {
      return jsonObject.toString();
    }
  }

  static String _formatBytes(int bytes) {
    const kb = 1024;
    if (bytes < kb) return '${bytes}B';
    final kbSize = bytes / kb;
    if (kbSize < kb) return '${kbSize.toStringAsFixed(1)}KB';
    final mbSize = kbSize / kb;
    return '${mbSize.toStringAsFixed(2)}MB';
  }

  static String _truncateIfNeeded(String text, {int maxLength = 2000}) {
    if (text.length <= maxLength) return text;
    final keepStart = (maxLength * 0.7).floor();
    final keepEnd = (maxLength * 0.3).floor();
    final truncated = text.length - keepStart - keepEnd;
    return '${text.substring(0, keepStart)}\n\n... [truncated $truncated characters] ...\n\n${text.substring(text.length - keepEnd)}';
  }

  static Map<String, String> _redactAuth(Map<String, String> headers) {
    final redacted = Map<String, String>.from(headers);
    final auth = redacted['Authorization'];
    if (auth != null && auth.startsWith('Bearer ')) {
      final token = auth.substring(7);
      if (token.length > 12) {
        redacted['Authorization'] =
            'Bearer ${token.substring(0, 6)}***${token.substring(token.length - 6)}';
      } else {
        redacted['Authorization'] = 'Bearer ***';
      }
    }

    return redacted;
  }

  static dynamic _safeDecode(String body) {
    try {
      return json.decode(body);
    } on Exception {
      return 'Failed to parse JSON: $body';
    }
  }

  /// Dispose resources
  void dispose() {
    _logStreamController.close();
  }
}
