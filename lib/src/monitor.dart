import 'dart:async' show Stream;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:monitor/src/core/monitor_storage.dart';
import 'package:monitor/src/core/stream_controller_manager.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/models/config.dart';
import 'package:monitor/src/output/console_printer.dart';
import 'package:monitor/src/privacy/monitor_redactor.dart';
import 'package:monitor/src/tracking/http_request_tracker.dart';
import 'package:monitor/src/tracking/message_logger.dart';

class Monitor {
  Monitor._();

  static final Monitor _instance = Monitor._();
  static Monitor get instance {
    _ensureInitialized();
    return _instance;
  }

  static late MonitorConfig _config;
  static MonitorConfig get config {
    _ensureInitialized();
    return _config;
  }

  static GlobalKey<NavigatorState>? navigatorKey;

  static bool _initialized = false;
  static bool _disposed = false;

  late MonitorStorage _storage;
  late StreamControllerManager _streamManager;
  late MonitorRedactor _redactor;
  late ConsolePrinter _printer;
  late HttpRequestTracker _httpTracker;
  late MessageLogger _messageLogger;

  Stream<List<LogEntry>> get logStream {
    _ensureInitialized();
    return _streamManager.stream;
  }

  List<LogEntry> get logs {
    _ensureInitialized();
    return _storage.logs;
  }

  List<HttpLogEntry> get httpLogs {
    _ensureInitialized();
    return _storage.httpLogs;
  }

  List<MessageLogEntry> get messageLogs {
    _ensureInitialized();
    return _storage.messageLogs;
  }

  List<LogEntry> get errorLogs {
    _ensureInitialized();
    return _storage.errorLogs;
  }

  List<HttpLogEntry> get successLogs {
    _ensureInitialized();
    return _storage.successLogs;
  }

  List<HttpLogEntry> get pendingLogs {
    _ensureInitialized();
    return _storage.pendingLogs;
  }

  List<LogEntry> search(String query) {
    _ensureInitialized();
    return _storage.search(query);
  }

  void clearLogs() {
    _ensureInitialized();
    _storage.clear();
    _streamManager.notify(_storage.logs);
  }

  static void init({MonitorConfig? config}) {
    final nextConfig = config ?? const MonitorConfig();
    if (_initialized && !_disposed) {
      if (_config == nextConfig) return;
      _config = nextConfig;
      _instance._reconfigure(nextConfig);
      return;
    }

    _config = nextConfig;
    _instance._initialize(nextConfig);
    _initialized = true;
    _disposed = false;
  }

  static void updateConfig(MonitorConfig newConfig) {
    if (!_initialized || _disposed) {
      init(config: newConfig);
      return;
    }
    if (_config == newConfig) return;
    _config = newConfig;
    _instance._reconfigure(newConfig);
    _instance._messageLogger.info('Monitor configuration updated');
  }

  static String startRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
    int? bodyBytes,
    Uint8List? bodyRawBytes,
  }) {
    _ensureInitialized();
    return _instance._httpTracker.startRequest(
      method: method,
      uri: uri,
      headers: headers,
      body: body,
      bodyBytes: bodyBytes,
      bodyRawBytes: bodyRawBytes,
    );
  }

  static void completeRequest({
    required String id,
    required int statusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
    int? responseSize,
  }) {
    _ensureInitialized();
    _instance._httpTracker.completeRequest(
      id: id,
      statusCode: statusCode,
      responseHeaders: responseHeaders,
      responseBody: responseBody,
      responseSize: responseSize,
    );
  }

  static void failRequest({
    required String id,
    required String errorMessage,
    bool isTimeout = false,
  }) {
    _ensureInitialized();
    _instance._httpTracker.failRequest(
      id: id,
      errorMessage: errorMessage,
      isTimeout: isTimeout,
    );
  }

  static void message(
    String msg, {
    MessageLevel level = MessageLevel.info,
    String? url,
  }) {
    _ensureInitialized();
    _instance._messageLogger.log(msg, level: level, url: url);
  }

  static void info(String msg) => message(msg);
  static void warning(String msg) => message(msg, level: MessageLevel.warning);
  static void error(String msg) => message(msg, level: MessageLevel.error);
  static void cacheHit({required String cacheKey}) =>
      message('Cache hit - served from memory', url: cacheKey);

  void dispose() {
    if (!_initialized || _disposed) return;
    _streamManager.dispose();
    _storage.clear();
    _initialized = false;
    _disposed = true;
  }

  static void _ensureInitialized() {
    if (_disposed) {
      throw StateError(
        'Monitor has been disposed. Call Monitor.init() to reinitialize.',
      );
    }
    if (!_initialized) {
      throw StateError(
        'Monitor has not been initialized. Call Monitor.init() first.',
      );
    }
  }

  void _initialize(MonitorConfig config) {
    _storage = MonitorStorage(config);
    _streamManager = StreamControllerManager();
    _redactor = MonitorRedactor(config);
    _printer = ConsolePrinter(config, _redactor);
    _httpTracker = HttpRequestTracker(
      storage: _storage,
      printer: _printer,
      redactor: _redactor,
      streamManager: _streamManager,
      config: config,
    );
    _messageLogger = MessageLogger(
      storage: _storage,
      printer: _printer,
      streamManager: _streamManager,
    );
    _printer.printInitialization();
  }

  void _reconfigure(MonitorConfig config) {
    _storage.updateConfig(config);
    _redactor = MonitorRedactor(config);
    _printer = ConsolePrinter(config, _redactor);
    _httpTracker = HttpRequestTracker(
      storage: _storage,
      printer: _printer,
      redactor: _redactor,
      streamManager: _streamManager,
      config: config,
    );
    _messageLogger = MessageLogger(
      storage: _storage,
      printer: _printer,
      streamManager: _streamManager,
    );
  }
}
