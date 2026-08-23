/// Layout tokens for the feed — the widths and media ratios the feed
/// column and its cards are built from.
///
/// These are deliberately *maximums and ratios*, never fixed sizes: the
/// feed column and every card inside it fill whatever width they're given
/// up to [columnMaxWidth], and media is sized by aspect ratio off that
/// width. That's what keeps a post card scaling in step with the rest of
/// the page under browser zoom — a card whose width is a fraction of the
/// viewport (e.g. a flex child of a two-column row) instead grows in
/// logical pixels exactly as fast as zooming out shrinks them, so its
/// media appears to stay the same size while all the surrounding text
/// shrinks.
abstract final class FeedLayout {
  /// Maximum width of the feed column (composer + tabs + cards) — the
  /// readable-column width the cards are designed around. Wider viewports
  /// leave gutters rather than stretching the cards.
  static const double columnMaxWidth = 720;

  /// Below this *card* width the card switches to its compact density
  /// (tighter gutters, smaller avatar/type). Read from the card's own
  /// constraints, not from `MediaQuery` — see `AppBreakpoints`, which
  /// stays the single place *screen* width is inspected.
  static const double compactCardWidth = 480;

  /// Ratio used for media whose real dimensions aren't known yet (still
  /// decoding, or failed to load). 16/9 matches the Cloudinary-derived
  /// video thumbnails, which are the most common case.
  static const double defaultMediaAspect = 16 / 9;

  /// Portrait limit — a taller-than-4:5 image is cropped to 4:5 rather
  /// than being allowed to swallow the whole viewport. Landscape limit —
  /// a wider-than-1.91:1 image is cropped rather than rendering as a
  /// letterbox strip.
  static const double minMediaAspect = 4 / 5;
  static const double maxMediaAspect = 1.91;
}
