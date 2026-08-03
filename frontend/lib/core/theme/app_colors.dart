import 'package:flutter/material.dart';

/// Brand palette derived from `assets/images/logo.png` (the Sport X Hub
/// "SX" mark: vivid azure blue on near-black, white wordmark).
abstract final class AppColors {
  // Brand
  static const Color brandBlue = Color(0xFF1476FF);
  static const Color brandBlueLight = Color(0xFF4FC3F7);
  static const Color brandBlueDark = Color(0xFF0B4FB0);

  // Neutral scale
  static const Color black = Color(0xFF0B0E14);
  static const Color charcoal = Color(0xFF12161F);
  static const Color slate = Color(0xFF1B212C);
  static const Color grey = Color(0xFF6B7686);
  static const Color greyLight = Color(0xFFA7B0BD);
  static const Color offWhite = Color(0xFFF7F9FC);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
