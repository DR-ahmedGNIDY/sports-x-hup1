// The Club dashboard's stat labels, at the width they actually get.
//
// M1 raised the base body size. Nothing overflowed — `ClubDashboardStatTile`
// ellipsises — so no exception was thrown and no test failed. The labels just
// silently became "ملفات غير مكتـ…" on a real phone, and it took a visual
// review of the deployed app to notice.
//
// Truncation is invisible to `takeException()`, so this asserts on the thing
// that is actually wrong: whether the paragraph reports that it ran out of
// lines.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/theme/app_spacing.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/features/dashboard/presentation/shared/club_dashboard_widgets.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

import '../../support/app_fonts.dart';

/// Two tiles side by side is what the mobile grid builds — a single tile
/// pumped full-width would have passed even before the fix.
Future<AppLocalizations> _pumpPair(
  WidgetTester tester, {
  required Size size,
  required String locale,
  required Widget Function(AppLocalizations) left,
  required Widget Function(AppLocalizations) right,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.compact(AppTheme.dark),
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            // The real screen inset — without it the tiles get more width
            // here than they ever get on the device.
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(child: left(l10n)),
                  const SizedBox(width: 8),
                  Expanded(child: right(l10n)),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return l10n;
}

/// Every laid-out paragraph showing [text] must have fitted within its
/// `maxLines` — `didExceedMaxLines` is true exactly when the ellipsis is
/// being drawn.
void _expectNotTruncated(WidgetTester tester, String text) {
  final paragraphs = tester
      .renderObjectList<RenderParagraph>(find.text(text))
      .toList();
  expect(paragraphs, isNotEmpty, reason: 'no paragraph rendered for "$text"');
  for (final paragraph in paragraphs) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '"$text" is truncated at this width',
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('ClubDashboardStatTile', () {
    // 375 is the narrowest width the app targets that still shows two tiles
    // per row; the labels here are the longest of the four.
    for (final phone in const <String, Size>{
      'iPhone SE': Size(375, 667),
      'small Android': Size(320, 640),
    }.entries) {
      testWidgets('shows the whole Arabic label on ${phone.key}', (
        tester,
      ) async {
        final l10n = await _pumpPair(
          tester,
          size: phone.value,
          locale: 'ar',
          left: (l10n) => ClubDashboardStatTile(
            icon: Icons.error_outline,
            label: l10n.clubDashboardIncompleteProfilesLabel,
            value: 3,
          ),
          right: (l10n) => ClubDashboardStatTile(
            icon: Icons.check_circle_outline,
            label: l10n.clubDashboardCompleteProfilesLabel,
            value: 7,
          ),
        );

        _expectNotTruncated(tester, l10n.clubDashboardIncompleteProfilesLabel);
        _expectNotTruncated(tester, l10n.clubDashboardCompleteProfilesLabel);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows the whole English label on the smallest phone', (
      tester,
    ) async {
      final l10n = await _pumpPair(
        tester,
        size: const Size(320, 640),
        locale: 'en',
        left: (l10n) => ClubDashboardStatTile(
          icon: Icons.error_outline,
          label: l10n.clubDashboardIncompleteProfilesLabel,
          value: 3,
        ),
        right: (l10n) => ClubDashboardStatTile(
          icon: Icons.groups_outlined,
          label: l10n.clubDashboardTotalPlayersLabel,
          value: 10,
        ),
      );

      _expectNotTruncated(tester, l10n.clubDashboardIncompleteProfilesLabel);
      _expectNotTruncated(tester, l10n.clubDashboardTotalPlayersLabel);
      expect(tester.takeException(), isNull);
    });
  });
}
