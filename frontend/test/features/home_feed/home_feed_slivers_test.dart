// Widget tests for the feed's sliver composition — the part that decides
// how wide the feed column gets, and what it shows when there's nothing
// (or nothing of the selected kind) to show.
//
// The width tests are the browser-zoom regression tests: zooming a browser
// out doesn't shrink the app, it hands Flutter a *larger* logical viewport
// at a smaller physical scale. So a column whose width is a fraction of
// the viewport stays the same apparent size while everything with a fixed
// logical size around it shrinks — which is exactly what "the page zooms
// but the video doesn't" looked like. Pumping the same widget at growing
// viewport widths reproduces that condition directly.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/features/home_feed/application/home_feed_controller.dart';
import 'package:sport_x_hub/features/home_feed/domain/entities/feed_author.dart';
import 'package:sport_x_hub/features/home_feed/domain/entities/feed_item.dart';
import 'package:sport_x_hub/features/home_feed/domain/entities/feed_page.dart';
import 'package:sport_x_hub/features/home_feed/presentation/shared/feed_item_card.dart';
import 'package:sport_x_hub/features/home_feed/presentation/shared/feed_layout.dart';
import 'package:sport_x_hub/features/home_feed/presentation/shared/home_feed_slivers.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

class _StubHomeFeedController extends HomeFeedController {
  _StubHomeFeedController(this.items, {this.total});

  final List<FeedItem> items;

  /// Larger than `items.length` to make the page report a next page.
  final int? total;

  int loadMoreCalls = 0;

  @override
  Future<HomeFeedState> build() async {
    return HomeFeedState(
      page: FeedPage(
        items: items,
        page: 1,
        pageSize: 20,
        total: total ?? items.length,
      ),
    );
  }

  /// Set to mimic the real controller's failure path — a fresh state
  /// object with the same items, i.e. a rebuild that adds nothing.
  bool failLoadMore = false;

  @override
  Future<void> loadMore() async {
    loadMoreCalls++;
    if (!failLoadMore) return;
    final current = state.value!;
    state = AsyncData(current.copyWith(loadingMore: false));
  }
}

FeedItem _item(String id, {FeedItemKind kind = FeedItemKind.photo}) {
  return FeedItem(
    kind: kind,
    id: id,
    secureUrl: 'https://example.test/$id.jpg',
    thumbnailUrl: 'https://example.test/$id.jpg',
    caption: 'Post $id',
    sport: 'Football',
    likeCount: 0,
    commentCount: 0,
    createdAt: DateTime.utc(2026, 8, 13, 9, 33),
    author: const FeedAuthor(role: 'CLUB', clubId: 'c1', displayName: 'Wadi Club'),
  );
}

/// Pumps [sliver] as the only content of a page-sized scroll view, at a
/// given logical viewport size — the same knob a browser zoom turns.
Future<void> _pumpAtWidth(
  WidgetTester tester,
  Widget sliver, {
  required double width,
  List<FeedItem> items = const [],
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeFeedControllerProvider.overrideWith(() => _StubHomeFeedController(items)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CustomScrollView(slivers: [sliver])),
      ),
    ),
  );
  // One extra pump for the controller's Future to resolve.
  await tester.pump();
}

void main() {
  group('FeedColumnSliver width', () {
    testWidgets('caps the column instead of tracking the viewport', (tester) async {
      // 1280 at 100% zoom, then the logical widths the same window
      // reports at 80%, 67% and 50% — the feed must not keep pace.
      for (final viewport in <double>[1600, 1920, 2560]) {
        await _pumpAtWidth(
          tester,
          FeedColumnSliver(kindFilter: null, onCreatePost: () {}),
          width: viewport,
          items: [_item('a')],
        );

        expect(
          tester.getSize(find.byType(FeedItemCard).first).width,
          FeedLayout.columnMaxWidth,
          reason: 'column should stay capped at a ${viewport}px viewport',
        );
      }
    });

    testWidgets('still fills the viewport when it is narrower than the cap', (tester) async {
      await _pumpAtWidth(
        tester,
        FeedColumnSliver(kindFilter: null, onCreatePost: () {}),
        width: 520,
        items: [_item('a')],
      );

      expect(tester.getSize(find.byType(FeedItemCard).first).width, 520);
    });

    testWidgets('header and cards share the same width', (tester) async {
      await _pumpAtWidth(
        tester,
        FeedColumnSliver(
          kindFilter: null,
          onCreatePost: () {},
          header: const SizedBox(key: ValueKey('header'), height: 40),
        ),
        width: 1600,
        items: [_item('a')],
      );

      expect(
        tester.getSize(find.byKey(const ValueKey('header'))).width,
        tester.getSize(find.byType(FeedItemCard).first).width,
      );
    });
  });

  group('HomeFeedSliver states', () {
    testWidgets('renders cards lazily — offscreen items are not built', (tester) async {
      await _pumpAtWidth(
        tester,
        const HomeFeedSliver(),
        width: 800,
        items: [_item('a'), _item('b'), _item('c')],
      );

      // Only what's near the viewport is built (the sliver list stays
      // lazy, exactly as the ListView.builder it replaced was)...
      expect(find.text('Post a'), findsOneWidget);
      expect(find.text('Post c'), findsNothing);

      // ...and the rest arrives on scroll.
      await tester.scrollUntilVisible(find.text('Post c'), 300);
      expect(find.text('Post c'), findsOneWidget);
    });

    testWidgets('kind filter hides the other content type', (tester) async {
      await _pumpAtWidth(
        tester,
        const HomeFeedSliver(kindFilter: FeedItemKind.video),
        width: 800,
        items: [_item('a'), _item('b', kind: FeedItemKind.video)],
      );

      expect(find.byType(FeedItemCard), findsOneWidget);
      expect(find.text('Post b'), findsOneWidget);
    });

    testWidgets('empty feed shows the designed empty state with its CTA', (tester) async {
      var created = 0;
      await _pumpAtWidth(
        tester,
        HomeFeedSliver(onCreatePost: () => created++),
        width: 800,
      );

      expect(find.byType(FeedEmptyState), findsOneWidget);
      await tester.tap(find.text('Create your first post'));
      expect(created, 1);
    });

    testWidgets('a filtered-empty tab does not offer the create CTA', (tester) async {
      await _pumpAtWidth(
        tester,
        HomeFeedSliver(kindFilter: FeedItemKind.video, onCreatePost: () {}),
        width: 800,
        items: [_item('a')],
      );

      expect(find.byType(FeedEmptyState), findsOneWidget);
      expect(find.text('Create your first post'), findsNothing);
    });

    testWidgets('fetches the next page as the end of the list comes into view', (tester) async {
      final controller = _StubHomeFeedController(
        [for (var i = 0; i < 6; i++) _item('$i')],
        total: 40,
      );
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [homeFeedControllerProvider.overrideWith(() => controller)],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: CustomScrollView(slivers: [HomeFeedSliver()]),
            ),
          ),
        ),
      );
      await tester.pump();

      // The first cards are on screen; the end is still far away.
      expect(controller.loadMoreCalls, 0);

      await tester.scrollUntilVisible(find.text('Post 5'), 400);
      await tester.pump();

      // Reaching the last few cards triggers the fetch, with no scroll
      // controller of the feed's own — the page owns the scroll now.
      expect(controller.loadMoreCalls, greaterThan(0));
    });

    testWidgets('a failed page load does not retry itself in a loop', (tester) async {
      final controller = _StubHomeFeedController(
        [for (var i = 0; i < 6; i++) _item('$i')],
        total: 40,
      )..failLoadMore = true;
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [homeFeedControllerProvider.overrideWith(() => controller)],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: CustomScrollView(slivers: [HomeFeedSliver()]),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Post 5'), 400);

      // Every failure hands the feed a fresh state object, so the list
      // rebuilds — but the request is tied to the loader row being
      // mounted, not built, so it doesn't fire again on those rebuilds.
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(controller.loadMoreCalls, 1);
    });

    testWidgets('renders in Arabic RTL without overflow', (tester) async {
      await _pumpAtWidth(
        tester,
        const HomeFeedSliver(),
        width: 420,
        items: [_item('a'), _item('b', kind: FeedItemKind.video)],
        locale: const Locale('ar'),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FeedItemCard), findsNWidgets(2));
      expect(Directionality.of(tester.element(find.byType(FeedItemCard).first)), TextDirection.rtl);
    });
  });
}
