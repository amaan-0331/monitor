import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:monitor/src/models/multipart_info.dart';
import 'package:monitor/src/utils/multipart_parser.dart';

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

String buildMultipartStringWithLf({
  required String boundary,
  required String fieldName,
  required String fieldValue,
  required String fileFieldName,
  required String fileName,
  required String fileContentType,
  required String fileContent,
}) {
  return '--$boundary\n'
      'Content-Disposition: form-data; name="$fieldName"\n\n'
      '$fieldValue\n'
      '--$boundary\n'
      'Content-Disposition: form-data; name="$fileFieldName"; '
      'filename="$fileName"\n'
      'Content-Type: $fileContentType\n\n'
      '$fileContent\n'
      '--$boundary--\n';
}

void main() {
  const boundary = 'boundary123';
  const headers = <String, String>{
    'Content-Type': 'multipart/form-data; boundary=boundary123',
  };

  test('parses multipart raw bytes and sizes parts accurately', () {
    final fileBytes = <int>[0, 255, 1, 2, 3];
    final bodyBytes = buildMultipartBytes(
      boundary: boundary,
      fieldName: 'field1',
      fieldValue: 'value1',
      fileFieldName: 'file1',
      fileName: 'a.bin',
      fileContentType: 'application/octet-stream',
      fileBytes: fileBytes,
    );

    final info = MultipartParser.parse(
      headers: headers,
      bodyRawBytes: bodyBytes,
    );

    expect(info, isNotNull);
    final parsed = info!;
    expect(parsed.parts.length, 2);
    expect(parsed.fileCount, 1);
    expect(parsed.fieldCount, 1);

    final fieldPart = parsed.parts.firstWhere(
      (MultipartPartInfo part) => !part.isFile,
    );
    final filePart = parsed.parts.firstWhere(
      (MultipartPartInfo part) => part.isFile,
    );

    expect(fieldPart.name, 'field1');
    expect(fieldPart.size, 'value1'.length);
    expect(filePart.filename, 'a.bin');
    expect(filePart.size, fileBytes.length);
    expect(parsed.totalSize, fieldPart.size + filePart.size);
  });

  test('parses multipart string fallback when bytes are not provided', () {
    const fieldValue = 'hello';
    const fileContent = 'file-content';
    final body = buildMultipartString(
      boundary: boundary,
      fieldName: 'field1',
      fieldValue: fieldValue,
      fileFieldName: 'file1',
      fileName: 'text.txt',
      fileContentType: 'text/plain',
      fileContent: fileContent,
    );

    final info = MultipartParser.parse(
      headers: headers,
      body: body,
    );

    expect(info, isNotNull);
    final parsed = info!;
    expect(parsed.parts.length, 2);

    final fieldPart = parsed.parts.firstWhere(
      (MultipartPartInfo part) => !part.isFile,
    );
    final filePart = parsed.parts.firstWhere(
      (MultipartPartInfo part) => part.isFile,
    );

    expect(fieldPart.size, fieldValue.length);
    expect(filePart.size, fileContent.length);
  });

  test('parses multipart with quoted boundary', () {
    const quotedHeaders = <String, String>{
      'Content-Type': 'multipart/form-data; boundary="boundary123"',
    };
    const fieldValue = 'alpha';
    const fileContent = 'beta';
    final body = buildMultipartString(
      boundary: boundary,
      fieldName: 'field1',
      fieldValue: fieldValue,
      fileFieldName: 'file1',
      fileName: 'quoted.txt',
      fileContentType: 'text/plain',
      fileContent: fileContent,
    );

    final info = MultipartParser.parse(
      headers: quotedHeaders,
      body: body,
    );

    expect(info, isNotNull);
    expect(info!.parts.length, 2);
  });

  test('parses multipart with LF-only separators', () {
    const fieldValue = 'one';
    const fileContent = 'two';
    final body = buildMultipartStringWithLf(
      boundary: boundary,
      fieldName: 'field1',
      fieldValue: fieldValue,
      fileFieldName: 'file1',
      fileName: 'lf.txt',
      fileContentType: 'text/plain',
      fileContent: fileContent,
    );

    final info = MultipartParser.parse(
      headers: headers,
      body: body,
    );

    expect(info, isNotNull);
    expect(info!.parts.length, 2);
  });

  test('parses multipart with many small fields', () {
    final buffer = StringBuffer();
    for (var i = 0; i < 50; i++) {
      buffer
        ..write('--$boundary\r\n')
        ..write('Content-Disposition: form-data; name="f$i"\r\n\r\n')
        ..write('v$i\r\n');
    }
    buffer.write('--$boundary--\r\n');

    final info = MultipartParser.parse(
      headers: headers,
      body: buffer.toString(),
    );

    expect(info, isNotNull);
    expect(info!.parts.length, 50);
    expect(info.fileCount, 0);
    expect(info.fieldCount, 50);
  });
}
