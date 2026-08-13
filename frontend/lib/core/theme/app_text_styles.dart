import 'package:flutter/material.dart';

/// Shared type scale used by both Desktop and Mobile presentation layers.
/// Individual screens should reference these rather than hardcoding styles,
/// so a single tweak here propagates everywhere.
abstract final class AppTextStyles {
  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Small uppercase label used for section eyebrows/category tags (e.g. the
  /// video category chip, skill-category tabs). Callers are responsible for
  /// calling `.toUpperCase()` on the text itself — a [TextStyle] can't
  /// transform case on its own.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 1.1,
  );

  /// Numeric style for counts/stats/percentages (dashboard completion,
  /// video like/comment counts, pagination). Tabular figures keep digit
  /// widths fixed so values don't jitter horizontally as they update.
  static const TextStyle statNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
