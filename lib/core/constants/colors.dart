import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevents instantiation

  /// Primary Orange (Used for buttons, highlights, selected states)
  static const Color orange = Color(0xFFFF6B00);
  static const Color yellow = Color(0xFFFF6B00); // alias for backwards compatibility
  static const Color goldenOrange = Color(0xFFFFB800);
  static const Color blue = Color(0xFF2563EB);
  static const Color green = Color(0xFF10B981); // Emerald Green

  /// Background colors
  static const Color darkBackground = Color(0xFF0A0C10);

  /// Neutral colors
  static const Color black = Color(0xFF000000); // Pure Black
  static const Color white = Color(0xFFFFFFFF); // Pure White

  /// Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textHint = Colors.white38;

  /// Input & card backgrounds
  static const Color fieldBackground = Colors.white10;

  /// Utility
  static const Color divider = Colors.white12;
}
