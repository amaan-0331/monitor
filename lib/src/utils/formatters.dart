import 'dart:convert';

String formatBytes(int bytes) {
  const kb = 1024;
  if (bytes < kb) return '${bytes}B';
  final kbSize = bytes / kb;
  if (kbSize < kb) return '${kbSize.toStringAsFixed(1)}KB';
  final mbSize = kbSize / kb;
  return '${mbSize.toStringAsFixed(2)}MB';
}

String prettyJson(dynamic jsonObject) {
  try {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonObject);
  } on Exception {
    return jsonObject.toString();
  }
}

String truncateIfNeeded(String text, {int maxLength = 2000}) {
  if (text.length <= maxLength) return text;
  final keepStart = (maxLength * 0.7).floor();
  final keepEnd = (maxLength * 0.3).floor();
  final truncated = text.length - keepStart - keepEnd;
  return '${text.substring(0, keepStart)}\n\n... [truncated $truncated characters] ...\n\n${text.substring(text.length - keepEnd)}';
}

Map<String, String> redactAuth(Map<String, String> headers) {
  final redacted = Map<String, String>.from(headers);
  final auth = redacted['Authorization'];
  if (auth != null && auth.startsWith('Bearer ')) {
    final token = auth.substring(7);
    if (token.length > 12) {
      redacted['Authorization'] =
          'Bearer ${token.substring(0, 6)}***${token.substring(token.length - 6)}';
    } else {
      redacted['Authorization'] = 'Bearer ***';
    }
  }

  return redacted;
}

dynamic safeDecode(String body) {
  try {
    return json.decode(body);
  } on Exception {
    return 'Failed to parse JSON: $body';
  }
}
