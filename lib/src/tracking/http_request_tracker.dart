import 'dart:convert' show utf8;
import 'package:monitor/src/core/monitor_storage.dart';
import 'package:monitor/src/core/stream_controller_manager.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/models/config.dart';
import 'package:monitor/src/output/console_printer.dart';
import 'package:monitor/src/privacy/monitor_redactor.dart';
import 'package:monitor/src/utils/id_generator.dart';

class HttpRequestTracker {
  HttpRequestTracker({
    required this.storage,
    required this.printer,
    required this.redactor,
    required this.streamManager,
    required this.config,
  });

  final MonitorStorage storage;
  final ConsolePrinter printer;
  final MonitorRedactor redactor;
  final StreamControllerManager streamManager;
  final MonitorConfig config;

  String startRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
    int? bodyBytes,
  }) {
    final url = uri.toString();
    final id = MonitorIdGenerator.generate('HTTP');
    storage.startStopwatch(id);

    final redactedHeaders = headers != null && config.logRequestHeaders
        ? redactor.redactHeaders(headers)
        : null;

    String? processedBody;
    int? processedSize;
    if (body != null && config.logRequestBody) {
      processedSize = bodyBytes ?? utf8.encode(body).length;
      processedBody = body;
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

    storage.addLog(entry);
    streamManager.notify(storage.logs);
    Future.microtask(() => printer.printRequest(entry));
    return id;
  }

  void completeRequest({
    required String id,
    required int statusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
    int? responseSize,
  }) {
    if (id.startsWith('HTTP-FILTERED')) return;
    final existing = storage.getLog(id);
    if (existing == null || existing is! HttpLogEntry) {
      Future.microtask(
        () => printer.printMessage(
          MessageLogEntry(
            id: MonitorIdGenerator.generate('MSG'),
            timestamp: DateTime.now(),
            level: MessageLevel.error,
            message:
                'Cannot complete request: ID $id not found or not an HTTP entry',
          ),
        ),
      );
      return;
    }

    final stopwatch = storage.getStopwatch(id);
    final duration = stopwatch != null
        ? Duration(microseconds: stopwatch.elapsedMicroseconds)
        : DateTime.now().difference(existing.timestamp);

    final state = statusCode >= 200 && statusCode < 400
        ? HttpLogState.success
        : HttpLogState.error;

    final redactedHeaders = responseHeaders != null && config.logResponseHeaders
        ? redactor.redactHeaders(responseHeaders)
        : null;

    String? processedBody;
    int? processedSize;
    if (responseBody != null && config.logResponseBody) {
      processedSize = responseSize ?? utf8.encode(responseBody).length;
      processedBody = responseBody;
    }

    final updated = existing.complete(
      state: state,
      statusCode: statusCode,
      duration: duration,
      responseHeaders: redactedHeaders,
      responseBody: processedBody,
      responseSize: processedSize,
    );

    storage
      ..updateLog(id, updated)
      ..removeStopwatch(id);
    streamManager.notify(storage.logs);
    Future.microtask(() => printer.printResponse(updated));
  }

  void failRequest({
    required String id,
    required String errorMessage,
    bool isTimeout = false,
  }) {
    if (id.startsWith('HTTP-FILTERED')) return;
    final existing = storage.getLog(id);
    if (existing == null || existing is! HttpLogEntry) {
      Future.microtask(
        () => printer.printMessage(
          MessageLogEntry(
            id: MonitorIdGenerator.generate('MSG'),
            timestamp: DateTime.now(),
            level: MessageLevel.error,
            message:
                'Cannot fail request: ID $id not found or not an HTTP entry',
          ),
        ),
      );
      return;
    }

    final stopwatch = storage.getStopwatch(id);
    final duration = stopwatch != null
        ? Duration(microseconds: stopwatch.elapsedMicroseconds)
        : DateTime.now().difference(existing.timestamp);

    final updated = existing.complete(
      state: isTimeout ? HttpLogState.timeout : HttpLogState.error,
      duration: duration,
      errorMessage: errorMessage,
    );

    storage
      ..updateLog(id, updated)
      ..removeStopwatch(id);
    streamManager.notify(storage.logs);
    Future.microtask(() => printer.printError(updated));
  }
}
