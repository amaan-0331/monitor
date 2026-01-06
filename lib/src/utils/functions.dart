import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:monitor/src/models/api_log_entry.dart';

void copyToClipboard(BuildContext context, {required LogEntry log}) {
  final text = switch (log) {
    HttpLogEntry entry => _formatHttpLog(entry),
    MessageLogEntry entry => _formatMessageLog(entry),
  };

  Clipboard.setData(ClipboardData(text: text));
}

String _formatHttpLog(HttpLogEntry log) {
  final buffer = StringBuffer()
    ..writeln('ID: ${log.id}')
    ..writeln('State: ${log.state.label}')
    ..writeln('Timestamp: ${log.timestamp.toIso8601String()}')
    ..writeln('Method: ${log.method}')
    ..writeln('URL: ${log.url}');

  if (log.statusCode != null) {
    buffer.writeln('Status: ${log.statusCode} (${log.statusCategory})');
  }
  if (log.duration != null) {
    buffer.writeln('Duration: ${log.durationText}');
  }
  if (log.requestSize != null) {
    buffer.writeln('Request Size: ${log.requestSizeText}');
  }
  if (log.responseSize != null) {
    buffer.writeln('Response Size: ${log.responseSizeText}');
  }
  if (log.errorMessage != null) {
    buffer
      ..writeln()
      ..writeln('Error:')
      ..writeln(log.errorMessage);
  }
  if (log.requestHeaders != null) {
    buffer
      ..writeln()
      ..writeln('Request Headers:')
      ..writeln(const JsonEncoder.withIndent('  ').convert(log.requestHeaders));
  }
  if (log.requestBody != null) {
    buffer
      ..writeln()
      ..writeln('Request Body:')
      ..writeln(log.prettyRequestBody ?? log.requestBody);
  }
  if (log.responseHeaders != null) {
    buffer
      ..writeln()
      ..writeln('Response Headers:')
      ..writeln(
        const JsonEncoder.withIndent('  ').convert(log.responseHeaders),
      );
  }
  if (log.responseBody != null) {
    buffer
      ..writeln()
      ..writeln('Response Body:')
      ..writeln(log.prettyResponseBody ?? log.responseBody);
  }

  return buffer.toString();
}

String _formatMessageLog(MessageLogEntry log) {
  final buffer = StringBuffer()
    ..writeln('ID: ${log.id}')
    ..writeln('Level: ${log.level.label}')
    ..writeln('Timestamp: ${log.timestamp.toIso8601String()}')
    ..writeln()
    ..writeln('Message:')
    ..writeln(log.message);

  if (log.url != null) {
    buffer
      ..writeln()
      ..writeln('URL: ${log.url}');
  }

  return buffer.toString();
}
