// Widget tests for the Club/Home feed post card's layout contract: the
// card and its media are width-driven (no fixed pixel sizes anywhere in
// the subtree), which is what makes them scale with the window — and with
// browser zoom — instead of staying put while the rest of the page
// shrinks. Also covers the "no fabricated engagement" rule: zero counts
// are omitted rather than rendered as "0".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/features/home_feed/domain/entities/feed_author.dart';
import 'package:sport_x_hub/features/home_feed/domain/entities/feed_item.dart';
import 'package:sport_x_hub/features/home_feed/presentation/shared/feed_item_card.dart';
import 'package:sport_x_hub/features/home_feed/presentation/shared/feed_layout.dart';
import 'package:sport_x_hub/features/home_feed/presentation/shared/feed_media.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

FeedItem _item({
  FeedItemKind kind = FeedItemKind.photo,
  String? caption,
  int likeCount = 0,
  int commentCount = 0,
}) {
  return FeedItem(
    kind: kind,
    id: 'post-1',
    secureUrl: 'https://example.test/media.jpg',
    thumbnailUrl: 'https://example.test/media.jpg',
    caption: caption,
    sport: 'Football',
    likeCount: likeCount,
    commentCount: commentCount,
    createdAt: DateTime.utc(2026, 8, 13, 9, 33),
    author: const FeedAuthor(role: 'CLUB', clubId: 'c1', displayName: 'Wadi Club'),
  );
}

Widget _wrap(Widget child, {Locale locale = const Locale('en'), double width = 720}) {
  return MaterialApp(
    // Feed widgets read colors via `context.profileColors`, which needs
    // the ProfileColors ThemeExtension AppTheme registers.
    theme: AppTheme.dark,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

double _widthOf(WidgetTester tester, Finder finder) =>
    tester.getSize(finder.first).width;

void main() {
  group('FeedItemCard layout', () {
    testWidgets('card and media fill the width they are given, at any width', (tester) async {
      for (final width in <double>[360, 480, 600, 720]) {
        await tester.pumpWidget(
          _wrap(
            FeedItemCard(
              item: _item(caption: 'New signing'),
              onToggleLike: () async {},
              onCommentTap: () {},
            ),
            width: width,
          ),
        );
        await tester.pump();

        // Card width minus its 1px hairline border on each side — the
        // media is edge-to-edge inside the card at every width.
        expect(
          _widthOf(tester, find.byType(FeedMedia)),
          closeTo(width - 2, 0.01),
          reason: 'media should track the card width at ${width}px, not a fixed size',
        );
      }
    });

    testWidgets('media keeps its aspect ratio as the available width changes', (tester) async {
      Future<Size> mediaSizeAt(double width) async {
        await tester.pumpWidget(
          _wrap(
            FeedItemCard(item: _item(), onToggleLike: () async {}, onCommentTap: () {}),
            width: width,
          ),
        );
        await tester.pump();
        return tester.getSize(find.byType(FeedMedia).first);
      }

      final wide = await mediaSizeAt(720);
      final narrow = await mediaSizeAt(360);

      expect(wide.width / wide.height, closeTo(narrow.width / narrow.height, 0.001));
      // Halving the available width halves the media — the behaviour that
      // was missing when the feed column was a pure fraction of the
      // viewport (browser zoom out grew the column, so the media never
      // appeared to shrink).
      expect(narrow.height, closeTo(wide.height / 2, 1.0));
    });

    testWidgets('never overflows horizontally, LTR or RTL', (tester) async {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        await tester.pumpWidget(
          _wrap(
            FeedItemCard(
              item: _item(
                kind: FeedItemKind.video,
                caption: 'تعاقد جديد — نرحب بانضمام اللاعب أحمد محمد إلى صفوف الفريق الأول',
                likeCount: 142,
                commentCount: 24,
              ),
              onToggleLike: () async {},
              onCommentTap: () {},
            ),
            locale: locale,
            width: 360,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'overflow in $locale');
      }
    });
  });

  group('FeedItemCard engagement', () {
    testWidgets('omits counts entirely when there is no engagement yet', (tester) async {
      await tester.pumpWidget(
        _wrap(FeedItemCard(item: _item(), onToggleLike: () async {}, onCommentTap: () {})),
      );
      await tester.pump();

      expect(find.text('0'), findsNothing);
      expect(find.text('0 comments'), findsNothing);
    });

    testWidgets('shows the real like and comment counts when present', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FeedItemCard(
            item: _item(likeCount: 142, commentCount: 24),
            onToggleLike: () async {},
            onCommentTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('142'), findsOneWidget);
      expect(find.text('24 comments'), findsOneWidget);
    });

    testWidgets('action bar offers exactly the three supported actions', (tester) async {
      await tester.pumpWidget(
        _wrap(FeedItemCard(item: _item(), onToggleLike: () async {}, onCommentTap: () {})),
      );
      await tester.pump();

      expect(find.text('Like'), findsOneWidget);
      expect(find.text('Comment'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('tapping Comment invokes the comment callback', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          FeedItemCard(
            item: _item(),
            onToggleLike: () async {},
            onCommentTap: () => tapped++,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Comment'));
      await tester.pump();

      expect(tapped, 1);
    });
  });

  group('FeedItemCard caption', () {
    testWidgets('offers "See more" only when the caption is actually clipped', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FeedItemCard(
            item: _item(caption: 'Short one.'),
            onToggleLike: () async {},
            onCommentTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('See more'), findsNothing);

      await tester.pumpWidget(
        _wrap(
          FeedItemCard(
            item: _item(caption: List.filled(200, 'a long caption line').join(' ')),
            onToggleLike: () async {},
            onCommentTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('See more'), findsOneWidget);

      await tester.tap(find.text('See more'));
      await tester.pump();
      expect(find.text('See less'), findsOneWidget);
    });
  });

  group('FeedLayout', () {
    test('caps the feed column instead of letting it track the viewport', () {
      expect(FeedLayout.columnMaxWidth, greaterThan(FeedLayout.compactCardWidth));
      expect(FeedLayout.minMediaAspect, lessThan(FeedLayout.maxMediaAspect));
    });
  });
}
