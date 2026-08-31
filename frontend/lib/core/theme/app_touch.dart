/// Minimum interactive-target sizes.
///
/// A control can look any size it likes; what it must not do is present a
/// tap area smaller than these values. Both platform guidelines land in the
/// same place for a reason — below roughly 44px, an adult fingertip starts
/// missing targets at a rate users read as "this app is janky", not "I
/// mis-tapped".
abstract final class AppTouch {
  /// 48px — Material's minimum, and the value this app targets everywhere.
  /// Chosen over the iOS 44 because it satisfies both.
  static const double minTarget = 48;

  /// 44px — Apple's Human Interface Guidelines minimum. Recorded for the
  /// rare case where a dense row genuinely cannot afford 48 and the design
  /// is iOS-first; [minTarget] is still the default.
  static const double iosMinTarget = 44;
}
