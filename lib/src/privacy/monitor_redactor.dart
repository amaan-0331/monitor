import 'dart:convert' show json;
import 'package:monitor/src/models/config.dart';
import 'package:monitor/src/utils/formatters.dart';

class MonitorRedactor {
  MonitorRedactor(this._config);
  final MonitorConfig _config;

  Map<String, String> redactHeaders(Map<String, String> headers) {
    final Map<String, String> redacted = <String, String>{};
    final List<String> redactionKeys = _config.headerRedactionKeys;
    final int? maxLen = _config.maxHeaderLength;

    for (final MapEntry<String, String> entry in headers.entries) {
      final String keyLower = entry.key.toLowerCase();
      String value = entry.value;

      for (final String redactKey in redactionKeys) {
        if (keyLower.contains(redactKey.toLowerCase())) {
          value = '***REDACTED***';
          break;
        }
      }

      if (maxLen != null && value.length > maxLen) {
        value = '${value.substring(0, maxLen)}...';
      }

      redacted[entry.key] = value;
    }

    return redacted;
  }

  String redactAndTruncateBody(String body) {
    String processed = body;
    try {
      final dynamic decoded = json.decode(body);
      final dynamic redacted = redactJsonObject(decoded);
      processed = prettyJson(redacted);
    } catch (_) {}
    return _config.truncateIfNeeded(processed, _config.maxBodyLength) ??
        processed;
  }

  dynamic redactJsonObject(dynamic obj) {
    if (obj is Map) {
      final Map<String, dynamic> redacted = <String, dynamic>{};
      final List<String> redactionKeys = _config.bodyRedactionKeys;
      for (final MapEntry<dynamic, dynamic> entry in obj.entries) {
        final String key = entry.key.toString();
        final String keyLower = key.toLowerCase();
        bool shouldRedact = false;
        for (final String redactKey in redactionKeys) {
          if (keyLower.contains(redactKey.toLowerCase())) {
            shouldRedact = true;
            break;
          }
        }
        if (shouldRedact) {
          redacted[key] = '***REDACTED***';
        } else if (entry.value is Map || entry.value is List) {
          redacted[key] = redactJsonObject(entry.value);
        } else {
          redacted[key] = entry.value;
        }
      }
      return redacted;
    } else if (obj is List) {
      return obj.map(redactJsonObject).toList();
    }
    return obj;
  }
}
