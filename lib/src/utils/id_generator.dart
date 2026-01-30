import 'dart:math' show Random;

/// Generates unique IDs for log entries.
class MonitorIdGenerator {
  static String generate(String prefix) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final pad = Random().nextInt(9999).toString().padLeft(4, '0');
    return '$prefix-$ts-$pad';
  }
}
