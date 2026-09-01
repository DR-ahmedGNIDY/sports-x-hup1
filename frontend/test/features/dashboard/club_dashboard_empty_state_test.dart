// A club that has just signed up sees the recent-players section before it
// sees anything else, and it used to be a grey sentence with no way forward.
//
// M3 settled what "there is nothing here" looks like — illustration, sentence,
// and the action that fixes it — but this section was never moved onto it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/core/widgets/empty_state_illustration.dart';
import 'package:sport_x_hub/core/widgets/mobile/app_empty_state.dart';
import 'package:sport_x_hub/features/club_players/domain/entities/club_dashboard_summary.dart';
import 'package:sport_x_hub/features/dashboard/presentation/shared/club_dashboard_widgets.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

import '../../support/app_fonts.dart';

const _emptySummary = ClubDashboardSummary(
  totalPlayers: 0,
  completeProfiles: 0,
  incompleteProfiles: 0,
  averageCompletionPercent: null,
  topMissingFields: [],
  recentPlayers: [],
);

/// A roster whose recent list is empty but whose count is not — the header
/// then carries both its title and the "view all" button, which is the
/// tightest that row ever gets.
const _crowdedHeaderSummary = ClubDashboardSummary(
  totalPlayers: 5,
  completeProfiles: 5,
  incompleteProfiles: 0,
  averageCompletionPercent: 100,
  topMissingFields: [],
  recentPlayers: [],
);

Future<AppLocalizations> _pump(
  WidgetTester tester,
  ClubDashboardSummary summary, {
  double textScale = 1.0,
  Size size = const Size(375, 812),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.compact(AppTheme.dark),
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return SingleChildScrollView(
              child: ClubDashboardRecentPlayersSection(summary: summary),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return l10n;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('an empty roster offers the way out of being empty', (
    tester,
  ) async {
    final l10n = await _pump(tester, _emptySummary);

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byType(EmptyStateIllustration), findsOneWidget);
    expect(find.text(l10n.clubDashboardEmptyStateHint), findsOneWidget);

    // The action, not just the explanation — a club with no players needs a
    // button more than it needs a sentence.
    expect(
      find.widgetWithText(FilledButton, l10n.clubPlayersAddPlayerLabel),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  // The header carries a title and a button in a `spaceBetween` row. At the
  // text size the people who most need it actually use, that row ran out of
  // width — the same failure M8 found in the navigation bar.
  testWidgets('the section header survives 2x text on a small phone', (
    tester,
  ) async {
    await _pump(
      tester,
      _crowdedHeaderSummary,
      textScale: 2.0,
      size: const Size(320, 640),
    );

    expect(tester.takeException(), isNull);
  });
}
