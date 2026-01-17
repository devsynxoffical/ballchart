import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevents instantiation

  /// Primary Yellow (Used for buttons, highlights, selected states)
  static const Color yellow = Color(0xFFF59E0B);
  // static const Color yellow = Color(0xFF2563EB);
  static const Color blue = Color(0xFF2563EB);

  /// Background colors
  static const Color darkBackground = Color(0xFF020617);

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
