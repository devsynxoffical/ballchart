import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0C10),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF6B00),
      secondary: Color(0xFFFFB800),
      surface: Color(0xFF141720),
    ),
    useMaterial3: true,
  );
}
