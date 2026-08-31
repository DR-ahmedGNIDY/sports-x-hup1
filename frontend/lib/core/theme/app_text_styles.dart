import 'package:flutter/material.dart';

/// Shared type scale used by both Desktop and Mobile presentation layers.
/// Individual screens should reference these rather than hardcoding styles,
/// so a single tweak here propagates everywhere.
abstract final class AppTextStyles {
  static const String fontFamily = 'Tajawal';

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

  // ---------------------------------------------------------------------
  // Compact (phone) scale
  //
  // The styles above were sized for a desktop browser, where 14px body text
  // sits at arm's length on a large display. Held in a hand, that same 14px
  // is the single clearest tell that you are reading a web page rather than
  // using an app: every native phone UI sets body text at 16–17. These are
  // the same styles one step up the scale, applied by
  // `AppTheme.compact` below the desktop breakpoint.
  //
  // Sizes only — family, weight and letter-spacing are inherited from the
  // base style so the two scales can never drift apart in anything but
  // size. `height` is adjusted where a larger size needs slightly tighter
  // leading to keep the same optical rhythm.
  // ---------------------------------------------------------------------

  /// Phone counterpart to [displayLarge] — also the large-title size for a
  /// collapsing app bar.
  static final TextStyle compactDisplayLarge = displayLarge.copyWith(
    fontSize: 34,
  );

  /// Phone counterpart to [headline].
  static final TextStyle compactHeadline = headline.copyWith(fontSize: 24);

  /// Phone counterpart to [title].
  static final TextStyle compactTitle = title.copyWith(fontSize: 20);

  /// Phone counterpart to [body] — the size that matters most.
  static final TextStyle compactBody = body.copyWith(fontSize: 16);

  /// Phone counterpart to [bodyStrong].
  static final TextStyle compactBodyStrong = bodyStrong.copyWith(fontSize: 16);

  /// Phone counterpart to [caption]. Bumped only one point: captions are
  /// deliberately secondary, and 14 here would compete with body text.
  static final TextStyle compactCaption = caption.copyWith(fontSize: 13);
}
