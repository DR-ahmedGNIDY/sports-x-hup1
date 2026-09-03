// A club profile that nobody has filled in still has to read as a profile.
//
// Every part of this view below the name is conditional — description,
// founded year, level — so an empty club rendered as a name floating over a
// blank screen, which reads as a page that failed to load.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/features/club/domain/entities/club_profile.dart';
import 'package:sport_x_hub/features/club/presentation/shared/club_profile_view.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

Future<AppLocalizations> _pump(WidgetTester tester, ClubProfile club) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.compact(AppTheme.dark),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return ClubProfileView(profile: club);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  testWidgets('an empty club says so instead of rendering a bare name', (
    tester,
  ) async {
    final l10n = await _pump(
      tester,
      const ClubProfile(id: 'c1', name: 'Zamalek Academy', publicCode: 'CLB-000003'),
    );

    expect(find.text('Zamalek Academy'), findsOneWidget);
    expect(
      find.text(l10n.clubProfileIncompleteNote),
      findsOneWidget,
      reason: 'a visitor could not tell an empty club from a broken page',
    );
  });

  testWidgets('a club with details shows them and drops the note', (
    tester,
  ) async {
    final l10n = await _pump(
      tester,
      const ClubProfile(
        id: 'c1',
        name: 'Al Ahly Youth Academy',
        city: 'Cairo',
        country: 'EG',
        description: 'A youth academy.',
        foundedYear: 1907,
      ),
    );

    expect(find.text('A youth academy.'), findsOneWidget);
    expect(find.text('1907'), findsOneWidget);
    expect(find.text(l10n.clubProfileIncompleteNote), findsNothing);
  });

  testWidgets('one detail alone is enough to drop the note', (tester) async {
    final l10n = await _pump(
      tester,
      const ClubProfile(id: 'c1', name: 'A Club', foundedYear: 2001),
    );

    expect(find.text(l10n.clubProfileIncompleteNote), findsNothing);
  });
}
