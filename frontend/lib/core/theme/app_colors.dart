import 'package:flutter/material.dart';

/// Brand palette for the SXH identity: a monochrome system — ink and paper —
/// taken from the white-on-black wordmark in `assets/brand/`. The accent is
/// black in the light theme and white in the dark one; colour is kept for
/// meaning (status) and for data visualizations only.
abstract final class AppColors {
  // Neutral scale — dark end
  static const Color black = Color(0xFF0A0A0A);
  static const Color charcoal = Color(0xFF141414);
  static const Color slate = Color(0xFF1C1C1C);
  static const Color graphite = Color(0xFF262626);

  // Neutral scale — light end
  static const Color grey = Color(0xFF6B6B70);
  static const Color greyLight = Color(0xFF9A9A9F);
  static const Color silver = Color(0xFFE6E6E8);
  static const Color mist = Color(0xFFF1F1F2);
  static const Color offWhite = Color(0xFFF4F4F5);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Legacy blue — kept only for the pitch/court position diagrams, which get
  // their own redesign separately. Nothing else should reach for these.
  static const Color brandBlue = Color(0xFF1476FF);
  static const Color brandBlueLight = Color(0xFF4FC3F7);
  static const Color brandBlueDark = Color(0xFF0B4FB0);

  // Football position visualization — primary-position marker on the
  // pitch diagram (design spec calls for this exact hex).
  static const Color pitchPrimary = Color(0xFF2563EB);

  // Player Profile dark palette.
  static const Color profileBg = black;
  static const Color profileSurface = charcoal;
  static const Color profileText = Color(0xFFFAFAFA);
  static const Color profileSecondary = Color(0xFF3B82F6);
  static const Color profileAccent = brandBlueLight;

  /// Neon green — active/current-status highlights on the Player Profile.
  static const Color profileNeonGreen = Color(0xFF39FF88);

  /// Gold — achievements/trophies accent on the Player Profile.
  static const Color profileGold = Color(0xFFE8B93B);
}
