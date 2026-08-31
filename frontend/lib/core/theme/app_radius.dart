/// Shared corner-radius scale, the counterpart to [AppSpacing] for
/// `BorderRadius` / `Radius` values. Screens reference these tokens rather
/// than hardcoding numeric literals, so the app's corner language stays
/// consistent and a single tweak here propagates everywhere.
///
/// Before this file existed the codebase held ten distinct radii — 4, 6, 8,
/// 10, 12, 14, 16, 20, 24 and 999 — across ~60 call sites. Most of that
/// spread was drift rather than design: nothing meaningful distinguishes a
/// 10px corner from a 12px one. The scale below keeps the values that were
/// carrying real intent and rounds the rest **up** to the next step, which
/// is also the direction this app is moving in — softer, larger corners are
/// what make a surface read as a native app card rather than a web panel.
///
/// Pick the closest token to the value you're replacing; if nothing fits
/// cleanly, that's a signal this scale needs an intermediate step rather
/// than a reason to reach for a raw literal.
abstract final class AppRadius {
  /// 4px — the tightest corner in the app: inline chips, progress-bar caps,
  /// small color swatches. Anything smaller reads as a square.
  static const double xxs = 4;

  /// 8px — compact controls and dense list rows.
  static const double xs = 8;

  /// 12px — default for buttons and inputs.
  static const double sm = 12;

  /// 16px — default for cards and other content surfaces.
  static const double md = 16;

  /// 20px — larger surfaces: hero panels, media containers, dialogs.
  static const double lg = 20;

  /// 28px — bottom sheets and full-bleed overlays. The largest corner that
  /// still reads as a rectangle.
  static const double xl = 28;

  /// Fully rounded — pills, avatars, circular buttons. Any value past half
  /// the shorter side produces a capsule, so the exact number is arbitrary;
  /// it just has to be large.
  static const double pill = 999;
}
