import 'package:flutter/widgets.dart';

/// Single source of truth for the Desktop/Mobile split. This is the ONLY
/// place layout width is inspected — individual features never branch on
/// `MediaQuery` themselves. See `ResponsiveShell` for how this is consumed.
abstract final class AppBreakpoints {
  /// Below this width, the Mobile presentation tree is mounted.
  /// At or above it, the Desktop presentation tree is mounted.
  static const double desktop = 900;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}
