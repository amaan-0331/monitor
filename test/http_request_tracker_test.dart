import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:monitor/src/core/monitor_storage.dart';
import 'package:monitor/src/core/stream_controller_manager.dart';
import 'package:monitor/src/models/api_log_entry.dart';
import 'package:monitor/src/models/config.dart';
import 'package:monitor/src/output/console_printer.dart';
import 'package:monitor/src/privacy/monitor_redactor.dart';
import 'package:monitor/src/tracking/http_request_tracker.dart';

Uint8List buildMultipartBytes({
  required String boundary,
  required String fieldName,
  required String fieldValue,
  required String fileFieldName,
  required String fileName,
  required String fileContentType,
  required List<int> fileBytes,
}) {
  final buffer = <int>[];

  void addString(String value) {
    buffer.addAll(utf8.encode(value));
  }

  addString('--$boundary\r\n');
  addString('Content-Disposition: form-data; name="$fieldName"\r\n\r\n');
  addString(fieldValue);
  addString('\r\n');

  addString('--$boundary\r\n');
  addString(
    'Content-Disposition: form-data; name="$fileFieldName"; '
    'filename="$fileName"\r\n',
  );
  addString('Content-Type: $fileContentType\r\n\r\n');
  buffer.addAll(fileBytes);
  addString('\r\n');

  addString('--$boundary--\r\n');

  return Uint8List.fromList(buffer);
}

String buildMultipartString({
  required String boundary,
  required String fieldName,
  required String fieldValue,
  required String fileFieldName,
  required String fileName,
  required String fileContentType,
  required String fileContent,
}) {
  return '--$boundary\r\n'
      'Content-Disposition: form-data; name="$fieldName"\r\n\r\n'
      '$fieldValue\r\n'
      '--$boundary\r\n'
      'Content-Disposition: form-data; name="$fileFieldName"; '
      'filename="$fileName"\r\n'
      'Content-Type: $fileContentType\r\n\r\n'
      '$fileContent\r\n'
      '--$boundary--\r\n';
}

void main() {
  const boundary = 'boundary123';
  const headers = <String, String>{
    'Content-Type': 'multipart/form-data; boundary=boundary123',
  };

  test('does not parse multipart when logRequestBody is false', () {
    const config = MonitorConfig(
      logRequestBody: false,
      consoleFormat: ConsoleLogFormat.none,
    );
    final storage = MonitorStorage(config);
    final streamManager = StreamControllerManager();
    final redactor = MonitorRedactor(config);
    final printer = ConsolePrinter(config, redactor);
    final tracker = HttpRequestTracker(
      storage: storage,
      printer: printer,
      redactor: redactor,
      streamManager: streamManager,
      config: config,
    );

    final body = buildMultipartString(
      boundary: boundary,
      fieldName: 'field1',
      fieldValue: 'value1',
      fileFieldName: 'file1',
      fileName: 'a.bin',
      fileContentType: 'application/octet-stream',
      fileContent: 'file-data',
    );

    final id = tracker.startRequest(
      method: 'POST',
      uri: Uri.parse('https://example.com/upload'),
      headers: headers,
      body: body,
    );

    final entry = storage.getLog(id)! as HttpLogEntry;
    expect(entry.multipartInfo, isNull);
    expect(entry.requestBody, isNull);
    expect(entry.requestSize, isNull);

    streamManager.dispose();
  });

  test('uses raw bytes and placeholder body when logRequestBody is true', () {
    const config = MonitorConfig(
      consoleFormat: ConsoleLogFormat.none,
    );
    final storage = MonitorStorage(config);
    final streamManager = StreamControllerManager();
    final redactor = MonitorRedactor(config);
    final printer = ConsolePrinter(config, redactor);
    final tracker = HttpRequestTracker(
      storage: storage,
      printer: printer,
      redactor: redactor,
      streamManager: streamManager,
      config: config,
    );

    final fileBytes = <int>[10, 20, 30, 40];
    final bodyBytes = buildMultipartBytes(
      boundary: boundary,
      fieldName: 'field1',
      fieldValue: 'value1',
      fileFieldName: 'file1',
      fileName: 'a.bin',
      fileContentType: 'application/octet-stream',
      fileBytes: fileBytes,
    );

    final id = tracker.startRequest(
      method: 'POST',
      uri: Uri.parse('https://example.com/upload'),
      headers: headers,
      bodyRawBytes: bodyBytes,
    );

    final entry = storage.getLog(id)! as HttpLogEntry;
    expect(entry.multipartInfo, isNotNull);
    expect(entry.requestBody, entry.multipartInfo!.placeholderBody);
    expect(entry.requestSize, bodyBytes.length);

    streamManager.dispose();
  });
}
