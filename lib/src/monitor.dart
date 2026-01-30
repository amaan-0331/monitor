import 'dart:async' show Stream;
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
  static Monitor get instance => _instance;

  static late MonitorConfig _config;
  static MonitorConfig get config => _config;

  static GlobalKey<NavigatorState>? navigatorKey;

  late final MonitorStorage _storage;
  late final StreamControllerManager _streamManager;
  late final MonitorRedactor _redactor;
  late final ConsolePrinter _printer;
  late final HttpRequestTracker _httpTracker;
  late final MessageLogger _messageLogger;

  Stream<List<LogEntry>> get logStream => _streamManager.stream;
  List<LogEntry> get logs => _storage.logs;
  List<HttpLogEntry> get httpLogs => _storage.httpLogs;
  List<MessageLogEntry> get messageLogs => _storage.messageLogs;
  List<LogEntry> get errorLogs => _storage.errorLogs;
  List<HttpLogEntry> get successLogs => _storage.successLogs;
  List<HttpLogEntry> get pendingLogs => _storage.pendingLogs;

  List<LogEntry> search(String query) => _storage.search(query);

  void clearLogs() {
    _storage.clear();
    _streamManager.notify(_storage.logs);
  }

  static void init({MonitorConfig? config}) {
    _config = config ?? MonitorConfig();

    _instance._storage = MonitorStorage(_config);
    _instance._streamManager = StreamControllerManager();
    _instance._redactor = MonitorRedactor(_config);
    _instance._printer = ConsolePrinter(_config);
    _instance._httpTracker = HttpRequestTracker(
      storage: _instance._storage,
      printer: _instance._printer,
      redactor: _instance._redactor,
      streamManager: _instance._streamManager,
      config: _config,
    );
    _instance._messageLogger = MessageLogger(
      storage: _instance._storage,
      printer: _instance._printer,
      streamManager: _instance._streamManager,
    );

    _instance._printer.printInitialization();
  }

  static void updateConfig(MonitorConfig newConfig) {
    _config = newConfig;
    _instance._messageLogger.info('Monitor configuration updated');
  }

  static String startRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
    int? bodyBytes,
  }) {
    return _instance._httpTracker.startRequest(
      method: method,
      uri: uri,
      headers: headers,
      body: body,
      bodyBytes: bodyBytes,
    );
  }

  static void completeRequest({
    required String id,
    required int statusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
    int? responseSize,
  }) {
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
    _instance._messageLogger.log(msg, level: level, url: url);
  }

  static void info(String msg) => message(msg, level: MessageLevel.info);
  static void warning(String msg) => message(msg, level: MessageLevel.warning);
  static void error(String msg) => message(msg, level: MessageLevel.error);
  static void cacheHit({required String cacheKey}) =>
      message('Cache hit - served from memory', url: cacheKey);

  void dispose() {
    _streamManager.dispose();
    _storage.clear();
  }
}
