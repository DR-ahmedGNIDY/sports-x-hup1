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

  // Football position visualization — primary-position marker on the
  // pitch diagram (design spec calls for this exact hex, distinct from
  // brandBlue).
  static const Color pitchPrimary = Color(0xFF2563EB);

  // Scouting-profile redesign — a dedicated dark palette for the Player
  // Profile hero/scouting layout, per design spec exact hex values
  // (distinct from the app-wide neutral scale above).
  static const Color profileBg = Color(0xFF0B0F14);
  static const Color profileSurface = Color(0xFF151B24);
  static const Color profileText = Color(0xFFF8FAFC);
  static const Color profileSecondary = Color(0xFF3B82F6);

  // Previously an independently-chosen blue (0xFF60A5FA) that didn't share
  // a relationship with the app-wide brand blue. Now aliased to
  // `brandBlueLight` — a lighter tint of `brandBlue` — so the profile/
  // skills/community accent reads as part of the same brand-blue family
  // instead of a separately-hued blue.
  static const Color profileAccent = brandBlueLight;

  // Player Profile premium-scouting-portfolio redesign — two additive
  // accents layered on top of the existing dark palette above. Deliberately
  // distinct from `success`/`warning` (which stay semantic status colors)
  // so a "neon glow" or "gold trophy" accent never gets confused with a
  // green success toast or an amber warning banner.
  /// Neon green — active/current-status highlights on the Player Profile
  /// (e.g. an "active" badge glow). Brighter/more saturated than `success`
  /// on purpose; `success` keeps its existing semantic meaning everywhere
  /// else (secondary position marker, completion-bar "done" state).
  static const Color profileNeonGreen = Color(0xFF39FF88);

  /// Gold — achievements/trophies accent on the Player Profile. Distinct
  /// from `warning` (amber, semantically "needs attention") even though
  /// the hues are neighbors.
  static const Color profileGold = Color(0xFFE8B93B);
}
