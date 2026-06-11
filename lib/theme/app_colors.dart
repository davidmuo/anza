import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFAFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color mutedText = Color(0xFF6B6B6B);
  static const Color border = Color(0xFFECECE8);

  static const Color primary = Color(0xFFFF5A36);
  static const Color secondary = Color(0xFF1E4D3B);
  static const Color verified = Color(0xFF2563EB);

  static const Color success = Color(0xFF1E9E5A);
  static const Color error = Color(0xFFD64545);

  static const List<Color> accentPalette = [
    Color(0xFFFF5A36),
    Color(0xFF1E4D3B),
    Color(0xFF2563EB),
    Color(0xFFE8A33D),
    Color(0xFF7C5CFC),
    Color(0xFF1E9E5A),
  ];

  static Color forSeed(String seed) {
    return accentPalette[seed.hashCode.abs() % accentPalette.length];
  }
}