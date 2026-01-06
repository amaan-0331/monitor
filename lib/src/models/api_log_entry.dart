import 'dart:convert';

class ApiLogEntry {
  ApiLogEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    this.method,
    this.url,
    this.statusCode,
    this.duration,
    this.requestHeaders,
    this.requestBody,
    this.responseBody,
    this.message,
    this.size,
  });

  final String id;
  final DateTime timestamp;
  final ApiLogType type;
  final String? method;
  final String? url;
  final int? statusCode;
  final Duration? duration;
  final Map<String, String>? requestHeaders;
  final String? requestBody;
  final String? responseBody;
  final String? message;
  final int? size;

  /// Returns the status category based on status code
  String get statusCategory {
    if (statusCode == null) return '';
    if (statusCode! >= 200 && statusCode! < 300) return 'SUCCESS';
    if (statusCode == 204) return 'NO CONTENT';
    if (statusCode! >= 400 && statusCode! < 500) return 'CLIENT ERROR';
    return 'SERVER ERROR';
  }

  // Status logic
  bool get isError =>
      statusCode != null && statusCode! >= 400 || type == ApiLogType.error;

  // Combine all size/meta logic into simple getters for the UI
  String get summary {
    if (type == ApiLogType.request) return '$method $shortUrl';
    if (type == ApiLogType.response) return '$statusCode $shortUrl';
    return message ?? '';
  }

  /// Returns a short display URL (path only)
  String get shortUrl {
    if (url == null) return '';
    try {
      final uri = Uri.parse(url!);
      final path = uri.path;
      if (path.length > 50) {
        return '...${path.substring(path.length - 47)}';
      }
      return path;
    } on FormatException {
      return url!;
    }
  }

  /// Returns formatted duration string
  String get durationText {
    if (duration == null) return '';
    return '${duration!.inMilliseconds}ms';
  }

  /// Returns formatted size string
  String get sizeText {
    if (size == null) return '';
    const kb = 1024;
    if (size! < kb) return '${size}B';
    final kbSize = size! / kb;
    if (kbSize < kb) return '${kbSize.toStringAsFixed(1)}KB';
    final mbSize = kbSize / kb;
    return '${mbSize.toStringAsFixed(2)}MB';
  }

  /// Returns formatted timestamp
  String get timeText {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$hour:$minute:$second.$ms';
  }

  /// Pretty prints JSON if possible
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

  /// Creates a copy with updated fields
  ApiLogEntry copyWith({
    String? id,
    DateTime? timestamp,
    ApiLogType? type,
    String? method,
    String? url,
    int? statusCode,
    Duration? duration,
    Map<String, String>? requestHeaders,
    String? requestBody,
    String? responseBody,
    String? message,
    int? size,
  }) {
    return ApiLogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      method: method ?? this.method,
      url: url ?? this.url,
      statusCode: statusCode ?? this.statusCode,
      duration: duration ?? this.duration,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      requestBody: requestBody ?? this.requestBody,
      responseBody: responseBody ?? this.responseBody,
      message: message ?? this.message,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.label,
      'method': method,
      'url': url,
      'statusCode': statusCode,
      'duration': duration?.inMilliseconds,
      'requestHeaders': requestHeaders,
      'requestBody': requestBody,
      'responseBody': responseBody,
      'message': message,
      'size': size,
    };
  }
}

/// Types of API log entries
enum ApiLogType {
  request('REQ'),
  response('RES'),
  error('ERR'), // For network failures/exceptions (no response)
  info('INFO'); // For system init, cache hits, or custom notes

  const ApiLogType(this.label);
  final String label;
}
