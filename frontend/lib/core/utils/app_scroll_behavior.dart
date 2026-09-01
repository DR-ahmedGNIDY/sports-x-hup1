import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// How scrolling feels.
///
/// Flutter Web defaults to the desktop clamping physics on every platform: a
/// list stops dead at its end. On a phone that is the single most legible
/// difference between a web page and an app — every native list overscrolls
/// and springs back, and its absence is felt before it is noticed.
///
/// Applied at the app root, so it reaches every scroll view including the ones
/// inside sheets and dialogs.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  /// A phone-width viewport gets the bouncing physics, a desktop one keeps
  /// clamping. Read from [AppBreakpoints], the same single place the rest of
  /// the app decides which presentation it is — a browser window dragged
  /// across the breakpoint changes both together.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      AppBreakpoints.isDesktop(context)
      ? const ClampingScrollPhysics()
      : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  /// Dragging with a mouse or trackpad, which Flutter Web otherwise refuses.
  /// Without it a desktop browser can only scroll these views with the wheel,
  /// and — the reason it matters here — neither can the automated checks that
  /// verify them.
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  /// The overscroll glow is Android's answer to the same problem the bouncing
  /// physics above already solves; showing both means a list that springs *and*
  /// flashes.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
