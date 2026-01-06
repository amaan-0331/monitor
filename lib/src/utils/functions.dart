import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monitor/src/models/api_log_entry.dart';

void copyToClipboard(BuildContext context, {required ApiLogEntry log}) {
  final buffer = StringBuffer()
    ..writeln('ID: ${log.id}')
    ..writeln('Type: ${log.type.label}')
    ..writeln('Timestamp: ${log.timestamp.toIso8601String()}');

  if (log.method != null) buffer.writeln('Method: ${log.method}');
  if (log.url != null) buffer.writeln('URL: ${log.url}');
  if (log.statusCode != null) {
    buffer.writeln('Status: ${log.statusCode} (${log.statusCategory})');
  }
  if (log.duration != null) buffer.writeln('Duration: ${log.durationText}');
  if (log.size != null) buffer.writeln('Size: ${log.sizeText}');
  if (log.message != null) buffer.writeln('\nMessage:\n${log.message}');
  if (log.requestHeaders != null) {
    buffer
      ..writeln('\nRequest Headers:')
      ..writeln(const JsonEncoder.withIndent('  ').convert(log.requestHeaders));
  }
  if (log.requestBody != null) {
    buffer
      ..writeln('\nRequest Body:')
      ..writeln(log.prettyRequestBody ?? log.requestBody);
  }
  if (log.responseBody != null) {
    buffer
      ..writeln('\nResponse Body:')
      ..writeln(log.prettyResponseBody ?? log.responseBody);
  }

  Clipboard.setData(ClipboardData(text: buffer.toString()));
}
