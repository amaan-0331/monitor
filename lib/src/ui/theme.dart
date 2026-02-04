import 'package:flutter/material.dart';

abstract class MonitorTheme {
  static ThemeData get data => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: CustomColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: CustomColors.surface,
      foregroundColor: CustomColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: const CardThemeData(color: CustomColors.surfaceContainer),
    dividerTheme: const DividerThemeData(color: CustomColors.divider),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: CustomColors.primary),
    ),
  );
}

abstract class CustomColors {
  static const Color surface = Color(0xFF121212);
  static const Color surfaceContainer = Color(0xFF1E1E1E);
  static const Color surfaceContainerHigh = Color(0xFF2D2D2D);
  static const Color onSurface = Color(0xFFE1E1E1);
  static const Color onSurfaceVariant = Color(0xFFB0B0B0);
  static const Color outline = Color(0xFF8A8A8A);
  static const Color outlineVariant = Color(0xFF444444);
  static const Color primary = Color(0xFF82B1FF);
  static const Color secondary = Color(0xFFB388FF);
  static const Color tertiary = Color(0xFF80CBC4);
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF69F0AE);
  static const Color warning = Color(0xFFFFD740);
  static const Color orange = Color(0xFFFFAB40);
  static const Color teal = Color(0xFF64FFDA);
  static const Color divider = Color(0xFF333333);
}
