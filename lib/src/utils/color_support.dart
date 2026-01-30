import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Detects whether ANSI colors are supported in the current terminal.
class ColorSupport {
  static bool? _cached;
  static bool get isSupported => _cached ??= _checkColorSupport();

  static bool _checkColorSupport() {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid ||
          Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux;
    } on Exception {
      return false;
    }
  }
}

/// ANSI color escape codes used for console output.
abstract class AnsiColors {
  static const reset = '\x1B[0m';
  static const red = '\x1B[31m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const blue = '\x1B[34m';
  static const cyan = '\x1B[36m';
  static const white = '\x1B[37m';
}
