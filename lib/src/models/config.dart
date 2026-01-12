import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Enums
// ═══════════════════════════════════════════════════════════════════════════

/// Console output format
enum ConsoleLogFormat {
  /// No console output
  none,

  /// Minimal single-line format
  simple,

  /// Full detailed box format with headers and bodies
  verbose;

  bool get isEnabled => this != ConsoleLogFormat.none;
}

// ═══════════════════════════════════════════════════════════════════════════
// Configuration Model
// ═══════════════════════════════════════════════════════════════════════════

/// Monitor configuration with all customization options
@immutable
class MonitorConfig {
  // Storage options
  final int maxLogs;
  final bool enableLogStorage;

  // Console output options
  final ConsoleLogFormat consoleFormat;

  // Content truncation
  final int? maxBodyLength; // null = no truncation
  final int? maxHeaderLength; // null = no truncation

  // Privacy & redaction
  final List<String> headerRedactionKeys;
  final List<String> bodyRedactionKeys;

  // Feature toggles
  final bool logRequestHeaders;
  final bool logResponseHeaders;
  final bool logRequestBody;
  final bool logResponseBody;

  const MonitorConfig({
    // Storage defaults
    this.maxLogs = 500,
    this.enableLogStorage = true,

    // Console defaults
    this.consoleFormat = ConsoleLogFormat.verbose,

    // Truncation defaults
    this.maxBodyLength = 10000, // 10KB default
    this.maxHeaderLength,

    // Redaction defaults
    this.headerRedactionKeys = const [
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'api-key',
    ],
    this.bodyRedactionKeys = const [
      'password',
      'token',
      'secret',
      'api_key',
      'apiKey',
      'access_token',
      'accessToken',
      'refresh_token',
      'refreshToken',
    ],

    // Feature toggle defaults
    this.logRequestHeaders = true,
    this.logResponseHeaders = true,
    this.logRequestBody = true,
    this.logResponseBody = true,
  });

  /// Create a copy with modified fields
  MonitorConfig copyWith({
    int? maxLogs,
    bool? enableLogStorage,
    ConsoleLogFormat? consoleFormat,
    int? maxBodyLength,
    int? maxHeaderLength,
    List<String>? headerRedactionKeys,
    List<String>? bodyRedactionKeys,
    bool? logRequestHeaders,
    bool? logResponseHeaders,
    bool? logRequestBody,
    bool? logResponseBody,
  }) {
    return MonitorConfig(
      maxLogs: maxLogs ?? this.maxLogs,
      enableLogStorage: enableLogStorage ?? this.enableLogStorage,
      consoleFormat: consoleFormat ?? this.consoleFormat,
      maxBodyLength: maxBodyLength ?? this.maxBodyLength,
      maxHeaderLength: maxHeaderLength ?? this.maxHeaderLength,
      headerRedactionKeys: headerRedactionKeys ?? this.headerRedactionKeys,
      bodyRedactionKeys: bodyRedactionKeys ?? this.bodyRedactionKeys,
      logRequestHeaders: logRequestHeaders ?? this.logRequestHeaders,
      logResponseHeaders: logResponseHeaders ?? this.logResponseHeaders,
      logRequestBody: logRequestBody ?? this.logRequestBody,
      logResponseBody: logResponseBody ?? this.logResponseBody,
    );
  }

  /// Truncate text if needed
  String? truncateIfNeeded(String? text, int? maxLength) {
    if (text == null || maxLength == null) return text;
    if (text.length <= maxLength) return text;

    const truncateMsg = '\n\n... [truncated]\n';
    return text.substring(0, maxLength - truncateMsg.length) + truncateMsg;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MonitorConfig &&
        other.maxLogs == maxLogs &&
        other.enableLogStorage == enableLogStorage &&
        other.consoleFormat == consoleFormat &&
        other.maxBodyLength == maxBodyLength &&
        other.maxHeaderLength == maxHeaderLength &&
        listEquals(other.headerRedactionKeys, headerRedactionKeys) &&
        listEquals(other.bodyRedactionKeys, bodyRedactionKeys) &&
        other.logRequestHeaders == logRequestHeaders &&
        other.logResponseHeaders == logResponseHeaders &&
        other.logRequestBody == logRequestBody &&
        other.logResponseBody == logResponseBody;
  }

  @override
  int get hashCode => Object.hash(
    maxLogs,
    enableLogStorage,
    consoleFormat,
    maxBodyLength,
    maxHeaderLength,
    Object.hashAll(headerRedactionKeys),
    Object.hashAll(bodyRedactionKeys),
    logRequestHeaders,
    logResponseHeaders,
    logRequestBody,
    logResponseBody,
  );
}
