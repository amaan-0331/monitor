import 'dart:convert' show json;
import 'package:monitor/src/models/config.dart';
import 'package:monitor/src/utils/formatters.dart';

class MonitorRedactor {
  MonitorRedactor(this._config);
  final MonitorConfig _config;

  Map<String, String> redactHeaders(Map<String, String> headers) {
    final redacted = <String, String>{};
    final redactionKeys = _config.headerRedactionKeys;
    final maxLen = _config.maxHeaderLength;

    for (final entry in headers.entries) {
      final keyLower = entry.key.toLowerCase();
      var value = entry.value;

      for (final redactKey in redactionKeys) {
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
    var processed = body;
    try {
      final dynamic decoded = json.decode(body);
      final dynamic redacted = redactJsonObject(decoded);
      processed = prettyJson(redacted);
    } on Exception catch (_) {}
    return _config.truncateIfNeeded(processed, _config.maxBodyLength) ??
        processed;
  }

  dynamic redactJsonObject(dynamic obj) {
    if (obj is Map) {
      final redacted = <String, dynamic>{};
      final redactionKeys = _config.bodyRedactionKeys;
      for (final entry in obj.entries) {
        final key = entry.key.toString();
        final keyLower = key.toLowerCase();
        var shouldRedact = false;
        for (final redactKey in redactionKeys) {
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
