// Phase Mobile M5 — the motion and touch rules.
//
// Two of these guard settings a user chose and the app has to honour; the
// third guards a platform difference that is easy to regress silently.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/utils/app_haptics.dart';
import 'package:sport_x_hub/core/utils/app_scroll_behavior.dart';

Widget _at(Size size, {required WidgetBuilder builder}) => MediaQuery(
  data: MediaQueryData(size: size),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Builder(builder: builder),
  ),
);

void main() {
  group('AppScrollBehavior', () {
    testWidgets('a phone scrolls with bouncing physics', (tester) async {
      late ScrollPhysics physics;
      await tester.pumpWidget(
        _at(
          const Size(390, 844),
          builder: (context) {
            physics = const AppScrollBehavior().getScrollPhysics(context);
            return const SizedBox();
          },
        ),
      );

      // The tell that separates a phone app from a web page: a list that
      // overscrolls and springs back rather than stopping dead.
      expect(physics, isA<BouncingScrollPhysics>());
    });

    testWidgets('a desktop window keeps clamping physics', (tester) async {
      late ScrollPhysics physics;
      await tester.pumpWidget(
        _at(
          const Size(1280, 800),
          builder: (context) {
            physics = const AppScrollBehavior().getScrollPhysics(context);
            return const SizedBox();
          },
        ),
      );

      expect(physics, isA<ClampingScrollPhysics>());
    });

    testWidgets('the phone physics still allow pull-to-refresh', (
      tester,
    ) async {
      // BouncingScrollPhysics alone will not overscroll a list shorter than
      // its viewport, which would leave pull-to-refresh unreachable on a
      // half-empty screen.
      late ScrollPhysics physics;
      await tester.pumpWidget(
        _at(
          const Size(390, 844),
          builder: (context) {
            physics = const AppScrollBehavior().getScrollPhysics(context);
            return const SizedBox();
          },
        ),
      );

      expect(physics.parent, isA<AlwaysScrollableScrollPhysics>());
    });

    test('a mouse and a trackpad can drag, not just the wheel', () {
      const behavior = AppScrollBehavior();
      expect(
        behavior.dragDevices,
        containsAll([PointerDeviceKind.mouse, PointerDeviceKind.trackpad]),
      );
    });

    testWidgets('no overscroll glow on top of the bounce', (tester) async {
      // Android's glow answers the same question the bounce already answers;
      // both at once is a list that springs and flashes.
      const child = SizedBox.shrink();
      late Widget wrapped;
      await tester.pumpWidget(
        _at(
          const Size(390, 844),
          builder: (context) {
            wrapped = const AppScrollBehavior().buildOverscrollIndicator(
              context,
              child,
              const ScrollableDetails(direction: AxisDirection.down),
            );
            return const SizedBox();
          },
        ),
      );

      expect(wrapped, same(child));
    });
  });

  group('AppHaptics', () {
    test('is a no-op on the web rather than a failed platform call', () async {
      // Every one of these runs in a plain test binding with no platform
      // channel answering. They must complete rather than throw: a tap
      // handler that raises because a device has no haptic engine loses the
      // tap, which is a far worse outcome than losing the buzz.
      await expectLater(AppHaptics.selection(), completes);
      await expectLater(AppHaptics.light(), completes);
      await expectLater(AppHaptics.success(), completes);
      await expectLater(AppHaptics.error(), completes);
    });
  });
}
