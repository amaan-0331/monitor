import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:monitor/src/ui/theme.dart';

/// Base sealed class for all log entries
sealed class LogEntry {
  LogEntry({
    required this.id,
    required this.timestamp,
  });

  final String id;
  final DateTime timestamp;

  /// Returns formatted timestamp (HH:MM:SS.mmm)
  String get timeText {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$hour:$minute:$second.$ms';
  }

  Map<String, dynamic> toJson();
}

/// HTTP request/response lifecycle entry
final class HttpLogEntry extends LogEntry {
  HttpLogEntry({
    required super.id,
    required super.timestamp,
    required this.method,
    required this.url,
    required this.state,
    this.requestHeaders,
    this.requestBody,
    this.requestSize,
    this.responseHeaders,
    this.responseBody,
    this.responseSize,
    this.statusCode,
    this.duration,
    this.errorMessage,
  });

  // Request data (immutable after creation)
  final String method;
  final String url;
  final Map<String, String>? requestHeaders;
  final String? requestBody;
  final int? requestSize;

  // Response data (populated when response arrives)
  final Map<String, String>? responseHeaders;
  final String? responseBody;
  final int? responseSize;
  final int? statusCode;
  final Duration? duration;
  final String? errorMessage;

  // Lifecycle state
  final HttpLogState state;

  // State helpers
  bool get isPending => state == HttpLogState.pending;
  bool get isSuccess => state == HttpLogState.success;
  bool get isError => state == HttpLogState.error || state == HttpLogState.timeout;
  bool get isCompleted => !isPending;

  /// Returns the status category based on status code
  String get statusCategory {
    if (statusCode == null) return '';
    if (statusCode == 204) return 'NO CONTENT';
    if (statusCode! >= 200 && statusCode! < 300) return 'SUCCESS';
    if (statusCode! >= 400 && statusCode! < 500) return 'CLIENT ERROR';
    return 'SERVER ERROR';
  }

  /// Returns a short display URL (path only)
  String get shortUrl {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.length > 50) {
        return '...${path.substring(path.length - 47)}';
      }
      return path.isEmpty ? '/' : path;
    } on FormatException {
      return url;
    }
  }

  /// Returns formatted duration string
  String get durationText {
    if (duration == null) return '';
    return '${duration!.inMilliseconds}ms';
  }

  /// Returns formatted request size string
  String get requestSizeText {
    if (requestSize == null) return '';
    return _formatBytes(requestSize!);
  }

  /// Returns formatted response size string
  String get responseSizeText {
    if (responseSize == null) return '';
    return _formatBytes(responseSize!);
  }

  /// Returns formatted size string (response size for backwards compat)
  String get sizeText => responseSizeText;

  String _formatBytes(int bytes) {
    const kb = 1024;
    if (bytes < kb) return '${bytes}B';
    final kbSize = bytes / kb;
    if (kbSize < kb) return '${kbSize.toStringAsFixed(1)}KB';
    final mbSize = kbSize / kb;
    return '${mbSize.toStringAsFixed(2)}MB';
  }

  /// Pretty prints response body JSON if possible
  String? get prettyResponseBody {
    if (responseBody == null) return null;
    try {
      final decoded = json.decode(responseBody!);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } on FormatException {
      return responseBody;
    }
  }

  /// Pretty prints request body JSON if possible
  String? get prettyRequestBody {
    if (requestBody == null) return null;
    try {
      final decoded = json.decode(requestBody!);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } on FormatException {
      return requestBody;
    }
  }

  /// Create updated entry with response data
  HttpLogEntry complete({
    required HttpLogState state,
    int? statusCode,
    Duration? duration,
    Map<String, String>? responseHeaders,
    String? responseBody,
    int? responseSize,
    String? errorMessage,
  }) {
    return HttpLogEntry(
      id: id,
      timestamp: timestamp,
      method: method,
      url: url,
      state: state,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      requestSize: requestSize,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      responseSize: responseSize ?? this.responseSize,
      statusCode: statusCode ?? this.statusCode,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': 'http',
      'state': state.label,
      'method': method,
      'url': url,
      'statusCode': statusCode,
      'duration': duration?.inMilliseconds,
      'requestHeaders': requestHeaders,
      'requestBody': requestBody,
      'requestSize': requestSize,
      'responseHeaders': responseHeaders,
      'responseBody': responseBody,
      'responseSize': responseSize,
      'errorMessage': errorMessage,
    };
  }
}

/// Simple message log entry (info, warning, error)
final class MessageLogEntry extends LogEntry {
  MessageLogEntry({
    required super.id,
    required super.timestamp,
    required this.level,
    required this.message,
    this.url,
  });

  final MessageLevel level;
  final String message;
  final String? url; // Optional context (e.g., for cache hits)

  bool get isError => level == MessageLevel.error;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': 'message',
      'level': level.label,
      'message': message,
      'url': url,
    };
  }
}

/// Lifecycle states for HTTP requests
enum HttpLogState {
  pending('PENDING'),
  success('SUCCESS'),
  error('ERROR'),
  timeout('TIMEOUT');

  const HttpLogState(this.label);
  final String label;

  Color get color {
    switch (this) {
      case HttpLogState.pending:
        return CustomColors.warning;
      case HttpLogState.success:
        return CustomColors.success;
      case HttpLogState.error:
        return CustomColors.error;
      case HttpLogState.timeout:
        return CustomColors.orange;
    }
  }
}

/// Message severity levels
enum MessageLevel {
  info('INFO'),
  warning('WARN'),
  error('ERROR');

  const MessageLevel(this.label);
  final String label;

  Color get color {
    switch (this) {
      case MessageLevel.info:
        return CustomColors.primary;
      case MessageLevel.warning:
        return CustomColors.warning;
      case MessageLevel.error:
        return CustomColors.error;
    }
  }
}
