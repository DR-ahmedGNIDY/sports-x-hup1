import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware palette for the Player Profile's "premium scouting
/// portfolio" surfaces (hero card, skills/traits pages, position pitches).
///
/// These surfaces used to hardcode [AppColors.profileBg] and friends
/// directly, which meant they stayed visually dark even when the app-wide
/// theme was switched to light. Every one of those raw constants now has a
/// light-mode counterpart here instead, looked up via
/// `Theme.of(context).extension<ProfileColors>()!`.
@immutable
class ProfileColors extends ThemeExtension<ProfileColors> {
  const ProfileColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.neonGreen,
    required this.gold,
    required this.borderOnSurface,
    required this.neutralBadgeBg,
  });

  /// Page/hero background.
  final Color bg;

  /// Card/section surface, sits on top of [bg].
  final Color surface;

  /// Secondary gradient stop used alongside [surface] in backdrops.
  final Color surfaceAlt;

  /// Primary text/icons on [bg] or [surface].
  final Color text;

  /// De-emphasized text/icons (was `AppColors.greyLight` everywhere).
  final Color textMuted;

  /// Brand accent for badges, links, highlighted labels.
  final Color accent;

  /// "Active/current" neon highlight accent.
  final Color neonGreen;

  /// Achievement/trophy accent.
  final Color gold;

  /// Base color for low-alpha hairline borders drawn over [bg]/[surface]
  /// (white in dark mode, black in light mode — apply `.withValues(alpha:)`
  /// at the call site same as before).
  final Color borderOnSurface;

  /// Fill for an "unselected" round badge (position code chips) — needs to
  /// stay visibly distinct from [surface] in both themes, so it can't just
  /// alias `bg`/`surface`. Paired with near-black text at the call site,
  /// same as the original always-light `AppColors.offWhite` fill.
  final Color neutralBadgeBg;

  static const dark = ProfileColors(
    bg: AppColors.profileBg,
    surface: AppColors.profileSurface,
    surfaceAlt: Color(0xFF0F1520),
    text: AppColors.profileText,
    textMuted: AppColors.greyLight,
    accent: AppColors.profileAccent,
    neonGreen: AppColors.profileNeonGreen,
    gold: AppColors.profileGold,
    borderOnSurface: AppColors.white,
    neutralBadgeBg: AppColors.offWhite,
  );

  static const light = ProfileColors(
    bg: AppColors.offWhite,
    surface: AppColors.white,
    surfaceAlt: Color(0xFFEDF2F9),
    text: AppColors.black,
    textMuted: AppColors.grey,
    accent: AppColors.brandBlue,
    neonGreen: Color(0xFF16A34A),
    gold: Color(0xFFAD7F17),
    borderOnSurface: AppColors.black,
    neutralBadgeBg: Color(0xFFE2E8F0),
  );

  @override
  ProfileColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? text,
    Color? textMuted,
    Color? accent,
    Color? neonGreen,
    Color? gold,
    Color? borderOnSurface,
    Color? neutralBadgeBg,
  }) {
    return ProfileColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      neonGreen: neonGreen ?? this.neonGreen,
      gold: gold ?? this.gold,
      borderOnSurface: borderOnSurface ?? this.borderOnSurface,
      neutralBadgeBg: neutralBadgeBg ?? this.neutralBadgeBg,
    );
  }

  @override
  ProfileColors lerp(ThemeExtension<ProfileColors>? other, double t) {
    if (other is! ProfileColors) return this;
    return ProfileColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      neonGreen: Color.lerp(neonGreen, other.neonGreen, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      borderOnSurface: Color.lerp(borderOnSurface, other.borderOnSurface, t)!,
      neutralBadgeBg: Color.lerp(neutralBadgeBg, other.neutralBadgeBg, t)!,
    );
  }
}

/// Shorthand so call sites read `context.profileColors.text` instead of
/// `Theme.of(context).extension<ProfileColors>()!.text`.
extension ProfileColorsContext on BuildContext {
  ProfileColors get profileColors => Theme.of(this).extension<ProfileColors>()!;
}
