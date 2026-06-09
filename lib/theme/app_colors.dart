import 'package:flutter/material.dart';

/// Anza's campus-energy color palette.
///
/// Kept as static constants (rather than a ThemeExtension) so the whole
/// team can reference `AppColors.primary` etc. directly without threading
/// BuildContext everywhere — simplest thing that works for a student demo.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFAFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color mutedText = Color(0xFF6B6B6B);
  static const Color border = Color(0xFFECECE8);

  static const Color primary = Color(0xFFFF5A36); // energetic coral
  static const Color secondary = Color(0xFF1E4D3B); // deep growth green
  static const Color verified = Color(0xFF2563EB);

  static const Color success = Color(0xFF1E9E5A);
  static const Color error = Color(0xFFD64545);

  /// Palette used for event banners / avatar backgrounds.
  /// Cycle through these instead of generating random colors so the
  /// app always looks intentional.
  static const List<Color> accentPalette = [
    Color(0xFFFF5A36),
    Color(0xFF1E4D3B),
    Color(0xFF2563EB),
    Color(0xFFE8A33D),
    Color(0xFF7C5CFC),
    Color(0xFF1E9E5A),
  ];
}
