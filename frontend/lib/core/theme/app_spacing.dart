/// Shared spacing scale used across the app for `EdgeInsets`, `SizedBox`
/// gaps, and gap-style layout values. Screens should reference these tokens
/// rather than hardcoding numeric literals, so the app's rhythm stays
/// consistent and a single tweak here propagates everywhere.
///
/// The scale is built on a 4px base unit — the unit already implicit in the
/// values scattered across the codebase (4/6/8/10/12/16/20/24/...) before
/// this file existed. Pick the closest token to the value you're replacing;
/// if nothing fits cleanly, that's a signal this scale needs an
/// intermediate step rather than a reason to reach for a raw literal.
abstract final class AppSpacing {
  /// 4px — hairline gaps (icon-to-label, chip padding).
  static const double xs = 4;

  /// 8px — tight gaps between closely related elements.
  static const double sm = 8;

  /// 12px — default gap between related elements within a component.
  static const double md = 12;

  /// 16px — standard padding/gap between components and screen edges.
  static const double lg = 16;

  /// 24px — gap between distinct sections within a screen.
  static const double xl = 24;

  /// 32px — larger section separation, generous screen padding.
  static const double xxl = 32;

  /// 48px — top-level layout separation (hero blocks, page-level margins).
  static const double xxxl = 48;
}
