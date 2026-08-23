// Direction regression test for the Club Home's two-column news section.
//
// `SliverCrossAxisGroup` places its first child on the left regardless of
// the ambient Directionality — verified, not assumed — so an RTL layout
// would otherwise put the feed (the primary column) on the left and the
// supporting column on the right, backwards for Arabic. ClubNewsColumns
// owns that flip; these tests pin both directions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sport_x_hub/features/dashboard/presentation/shared/club_news_columns.dart';

const _feedKey = ValueKey('feed');
const _secondaryKey = ValueKey('secondary');

Future<void> _pump(WidgetTester tester, TextDirection direction) {
  return tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: CustomScrollView(
        slivers: [
          const ClubNewsColumns(
            feed: SliverToBoxAdapter(child: SizedBox(key: _feedKey, height: 100)),
            secondary: SliverToBoxAdapter(child: SizedBox(key: _secondaryKey, height: 100)),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('ClubNewsColumns', () {
    testWidgets('puts the feed on the left in LTR', (tester) async {
      await _pump(tester, TextDirection.ltr);

      expect(
        tester.getTopLeft(find.byKey(_feedKey)).dx,
        lessThan(tester.getTopLeft(find.byKey(_secondaryKey)).dx),
      );
    });

    testWidgets('puts the feed on the right in RTL', (tester) async {
      await _pump(tester, TextDirection.rtl);

      expect(
        tester.getTopLeft(find.byKey(_feedKey)).dx,
        greaterThan(tester.getTopLeft(find.byKey(_secondaryKey)).dx),
      );
    });

    testWidgets('gives the feed the larger share of the width, both directions', (tester) async {
      for (final direction in TextDirection.values) {
        await _pump(tester, direction);

        expect(
          tester.getSize(find.byKey(_feedKey)).width,
          greaterThan(tester.getSize(find.byKey(_secondaryKey)).width),
          reason: 'feed should be the primary column in $direction',
        );
      }
    });

    testWidgets('keeps the gutter between the columns, not outside them', (tester) async {
      for (final direction in TextDirection.values) {
        await _pump(tester, direction);

        final feed = tester.getRect(find.byKey(_feedKey));
        final secondary = tester.getRect(find.byKey(_secondaryKey));
        final viewport = tester.getRect(find.byType(CustomScrollView));

        // Neither column is inset from the outer edges of the section...
        expect(
          <double>[feed.left, secondary.left].reduce((a, b) => a < b ? a : b),
          viewport.left,
          reason: 'no leading dead space in $direction',
        );
        expect(
          <double>[feed.right, secondary.right].reduce((a, b) => a > b ? a : b),
          viewport.right,
          reason: 'no trailing dead space in $direction',
        );
        // ...and they don't touch each other.
        final gap = feed.left < secondary.left
            ? secondary.left - feed.right
            : feed.left - secondary.right;
        expect(gap, greaterThan(0), reason: 'columns should be separated in $direction');
      }
    });
  });
}
