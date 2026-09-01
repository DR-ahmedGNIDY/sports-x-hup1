// Regression test for the NaN layout exception a release build logged twice
// on *every* authenticated route:
//
//   Unsupported operation: Result of truncating division is NaN:
//   NaN ~/ 182.11765423943015
//
// The divisor is a SliverGrid main-axis stride. The repeating 1/17 fraction
// in it is the signature of dividing by 0.85, which identifies
// `_skillsGridDelegate` in skills_section.dart; the two distinct values seen
// (182.1176 and 206.8235) correspond exactly to the two container widths the
// Skills section renders at — inside a profile section card, and on the
// Skills page.
//
// The cause was VideoGridSkeleton: a fully scrollable GridView nested inside
// another scroll view. It asked for unbounded height, and its own scroll
// offset resolved to NaN. It fired on every route rather than only on Skills
// because the loading state is on screen before data arrives, and
// StatefulShellRoute.indexedStack keeps every branch mounted at once.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/videos/presentation/shared/video_card_skeleton.dart';

const _delegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 260,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  childAspectRatio: 0.85,
);

void main() {
  testWidgets('lays out inside a box scroll view without error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VideoGridSkeleton(gridDelegate: _delegate, itemCount: 3),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out inside a sliver scroll view without error', (
    tester,
  ) async {
    // The arrangement the app actually uses after the M4 migration: every
    // migrated screen is a CustomScrollView, and the Skills section reaches
    // this skeleton through a SliverToBoxAdapter.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: VideoGridSkeleton(gridDelegate: _delegate, itemCount: 3),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('does not scroll on its own', (tester) async {
    // It stands in for grids that are themselves non-scrolling; a skeleton
    // that scrolls independently would let the placeholder move while the
    // page behind it stays put.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VideoGridSkeleton(gridDelegate: _delegate, itemCount: 3),
          ),
        ),
      ),
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.shrinkWrap, isTrue);
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
  });
}
