// The cross-cutting checks for the feed redesign: the browser-zoom
// matrix, real phone widths, both themes, and the video/loading/error
// variants of a card. Kept separate from the per-widget tests so the
// matrix can grow without turning those into a table of loops.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/core/theme/profile_colors.dart';
import 'package:sport_x_hub/core/widgets/skeleton_box.dart';
import 'package:sport_x_hub/features/home_feed/application/home_feed_controller.dart';
import 'package:sport_x_hub/features/home_feed/domain/entities/feed_author.dart';
import 'package:sport_x_hub/features/home_feed/domain/entities/feed_item.dart';
import 'package:sport_x_hub/features/home_feed/domain/entities/feed_page.dart';
import 'package:sport_x_hub/features/home_feed/presentation/shared/feed_item_card.dart';
import 'package:sport_x_hub/features/home_feed/presentation/shared/feed_layout.dart';
import 'package:sport_x_hub/features/home_feed/presentation/shared/feed_media.dart';
import 'package:sport_x_hub/features/home_feed/presentation/shared/home_feed_slivers.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

class _StubController extends HomeFeedController {
  _StubController(this.items);

  final List<FeedItem> items;

  @override
  Future<HomeFeedState> build() async => HomeFeedState(
    page: FeedPage(items: items, page: 1, pageSize: 20, total: items.length),
  );
}

/// Never completes — holds the feed in its loading state.
class _LoadingController extends HomeFeedController {
  @override
  Future<HomeFeedState> build() => Completer<HomeFeedState>().future;
}

class _FailingController extends HomeFeedController {
  @override
  Future<HomeFeedState> build() async => throw Exception('offline');
}

FeedItem _item({
  FeedItemKind kind = FeedItemKind.photo,
  String? caption = 'Post caption',
  int likeCount = 142,
  int commentCount = 24,
}) {
  return FeedItem(
    kind: kind,
    id: 'p1',
    secureUrl: 'https://example.test/p1.mp4',
    thumbnailUrl: 'https://example.test/p1.jpg',
    caption: caption,
    sport: 'Football',
    likeCount: likeCount,
    commentCount: commentCount,
    createdAt: DateTime.utc(2026, 8, 13, 9, 33),
    author: const FeedAuthor(role: 'CLUB', clubId: 'c1', displayName: 'نادي الوادي'),
  );
}

Future<void> _pumpFeed(
  WidgetTester tester, {
  required Size viewport,
  required HomeFeedController Function() controller,
  ThemeData? theme,
  Locale locale = const Locale('en'),
  Widget Function()? sliver,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [homeFeedControllerProvider.overrideWith(controller)],
      child: MaterialApp(
        theme: theme ?? AppTheme.dark,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [sliver?.call() ?? const FeedColumnSliver()],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('browser zoom matrix', () {
    // A 1280x800 window reports these logical sizes as the user zooms out
    // (100% → 50%). The card must keep the *same logical* width, which is
    // what makes it shrink on screen along with everything else; a column
    // that tracked the viewport would grow through this list instead.
    const zoomLevels = <String, Size>{
      '100%': Size(1280, 800),
      '90%': Size(1422, 889),
      '80%': Size(1600, 1000),
      '75%': Size(1707, 1067),
      '67%': Size(1910, 1194),
      '50%': Size(2560, 1600),
    };

    testWidgets('card width never grows with the viewport', (tester) async {
      for (final entry in zoomLevels.entries) {
        await _pumpFeed(
          tester,
          viewport: entry.value,
          controller: () => _StubController([_item()]),
        );

        expect(
          tester.getSize(find.byType(FeedItemCard).first).width,
          FeedLayout.columnMaxWidth,
          reason: 'at ${entry.key} zoom (${entry.value.width}px logical)',
        );
      }
    });

    testWidgets('media keeps pace with the card at every zoom level', (tester) async {
      for (final entry in zoomLevels.entries) {
        await _pumpFeed(
          tester,
          viewport: entry.value,
          controller: () => _StubController([_item(kind: FeedItemKind.video)]),
        );

        final card = tester.getSize(find.byType(FeedItemCard).first);
        final media = tester.getSize(find.byType(FeedMedia).first);
        expect(
          media.width,
          card.width - 2,
          reason: 'media should span the card at ${entry.key} zoom',
        );
      }
    });
  });

  group('phone widths', () {
    // These run under `AppTheme.compact`, not the base theme: below the
    // Desktop breakpoint the real app re-types itself one step up the scale
    // (16px body instead of 14 — see AppTheme.compact), and a card that only
    // fits at the smaller size isn't actually passing this test.
    final phoneTheme = AppTheme.compact(AppTheme.dark);

    // Smallest widely-used phone width up to a large one.
    for (final width in <double>[320, 360, 390, 430]) {
      testWidgets('renders without overflow at ${width}px', (tester) async {
        await _pumpFeed(
          tester,
          viewport: Size(width, 780),
          controller: () => _StubController([_item(kind: FeedItemKind.video)]),
          theme: phoneTheme,
          locale: const Locale('ar'),
        );

        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(FeedItemCard).first).width, width);
      });
    }

    testWidgets('action labels stay legible instead of being clipped away', (tester) async {
      await _pumpFeed(
        tester,
        viewport: const Size(320, 780),
        controller: () => _StubController([_item()]),
        theme: phoneTheme,
      );

      for (final label in ['Like', 'Comment', 'Share']) {
        expect(find.text(label), findsOneWidget, reason: '$label should still be rendered');
      }
    });
  });

  group('themes', () {
    testWidgets('renders in the light theme with theme-driven colors', (tester) async {
      await _pumpFeed(
        tester,
        viewport: const Size(800, 900),
        controller: () => _StubController([_item()]),
        theme: AppTheme.light,
      );

      expect(tester.takeException(), isNull);

      final context = tester.element(find.byType(FeedItemCard).first);
      final expected = Theme.of(context).extension<ProfileColors>()!.text;
      final authorName = tester.widget<Text>(find.text('نادي الوادي'));
      expect(
        authorName.style?.color,
        expected,
        reason: 'card text must follow the theme, not a hardcoded dark-mode color',
      );
    });
  });

  group('card variants', () {
    testWidgets('a video post gets the play affordance', (tester) async {
      await _pumpFeed(
        tester,
        viewport: const Size(800, 900),
        controller: () => _StubController([_item(kind: FeedItemKind.video)]),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('a photo post does not', (tester) async {
      await _pumpFeed(
        tester,
        viewport: const Size(800, 900),
        controller: () => _StubController([_item()]),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('a caption-less post still renders media and actions', (tester) async {
      await _pumpFeed(
        tester,
        viewport: const Size(800, 900),
        controller: () => _StubController([_item(caption: null)]),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FeedMedia), findsOneWidget);
      expect(find.text('Like'), findsOneWidget);
    });

    testWidgets('loading shows card-shaped skeletons, not a bare spinner', (tester) async {
      await _pumpFeed(
        tester,
        viewport: const Size(800, 900),
        controller: _LoadingController.new,
      );

      expect(find.byType(FeedItemCardSkeleton), findsWidgets);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('error shows a retry affordance', (tester) async {
      await _pumpFeed(
        tester,
        viewport: const Size(800, 900),
        controller: _FailingController.new,
      );

      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
