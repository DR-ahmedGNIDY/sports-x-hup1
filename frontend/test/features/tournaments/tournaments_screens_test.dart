// The tournament screens rendered for real with sample data — no network —
// at phone and desktop widths, in both languages. Any layout overflow,
// exception or missing label fails the test. Adapted from the reference
// implementation's screen tests.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/player/application/lookup_providers.dart';
import 'package:sport_x_hub/features/player/domain/entities/lookup_option.dart';
import 'package:sport_x_hub/features/tournaments/data/tournaments_repository.dart';
import 'package:sport_x_hub/features/tournaments/domain/tournament.dart';
import 'package:sport_x_hub/features/tournaments/presentation/club_tournaments_pages.dart';
import 'package:sport_x_hub/features/tournaments/presentation/player_tournaments_pages.dart';
import 'package:sport_x_hub/features/tournaments/presentation/tournament_form_page.dart';
import 'package:sport_x_hub/features/tournaments/presentation/tournament_widgets.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

Map<String, dynamic> _fx(
  String id,
  String stage,
  int round,
  int no,
  String? a,
  String? b, {
  int? sa,
  int? sb,
  String? w,
  String status = 'pending',
  int? g,
}) => {
  'id': id,
  'stage': stage,
  'round': round,
  'matchNo': no,
  'aId': a,
  'bId': b,
  'scoreA': sa,
  'scoreB': sb,
  'winnerId': w,
  'status': status,
  'groupIndex': g,
  'sets': const [],
  'date': '2026-11-10',
  'time': '17:00',
  'location': 'Academy pitch',
};

Map<String, dynamic> _row(String id, int pos, int pts) => {
  'id': id,
  'position': pos,
  'played': 3,
  'won': pts ~/ 3,
  'drawn': pts % 3,
  'lost': 3 - pts ~/ 3 - pts % 3,
  'diff': pts - 4,
  'points': pts,
};

/// Groups then knockout, teams, goals with penalties — partly played.
final _groupsDetail = TournamentDetail.fromJson({
  'tournament': {
    'id': 't1',
    'name': 'Winter Cup',
    'participantType': 'team',
    'format': 'groups_knockout',
    'drawMode': 'directed',
    'status': 'running',
    'scoring': {'mode': 'goals'},
    'league': {'winPoints': 3, 'drawPoints': 1, 'lossPoints': 0},
    'groups': {'count': 2, 'qualifiersPerGroup': 1},
    'knockout': {'penaltiesEnabled': true, 'penaltiesCount': 5},
    'visibleToPlayers': true,
  },
  'participants': [
    for (final (i, name) in ['Lions', 'Tigers', 'Eagles', 'Sharks'].indexed)
      {
        'id': 'p${i + 1}',
        'name': name,
        'playerUserIds': ['u${i + 1}a', 'u${i + 1}b'],
        'captainUserId': 'u${i + 1}a',
        'seed': i + 1,
        'groupIndex': i % 2,
      },
  ],
  'players': [
    for (var i = 1; i <= 4; i++) ...[
      {'userId': 'u${i}a', 'firstName': 'Player', 'lastName': '${i}A'},
      {'userId': 'u${i}b', 'firstName': 'Player', 'lastName': '${i}B'},
    ],
  ],
  'fixtures': [
    _fx('f1', 'group', 1, 1, 'p1', 'p3', sa: 2, sb: 1, w: 'p1', status: 'played', g: 0),
    _fx('f2', 'group', 1, 1, 'p2', 'p4', g: 1),
    _fx('f3', 'knockout', 1, 1, 'p1', null),
  ],
  'standings': [
    {
      'groupIndex': 0,
      'rows': [_row('p1', 1, 3), _row('p3', 2, 0)],
    },
    {
      'groupIndex': 1,
      'rows': [_row('p2', 1, 0), _row('p4', 2, 0)],
    },
  ],
  'myParticipantId': 'p1',
});

/// A draft league of individuals, nothing scheduled yet.
final _draftDetail = TournamentDetail.fromJson({
  'tournament': {
    'id': 't2',
    'name': 'Table tennis league',
    'participantType': 'individual',
    'format': 'league',
    'drawMode': 'directed',
    'status': 'draft',
    'scoring': {'mode': 'sets', 'bestOf': 3, 'pointsPerSet': 11},
  },
  'participants': [
    {'id': 'p1', 'name': 'Omar Salah', 'playerUserIds': ['u1'], 'seed': 1},
    {'id': 'p2', 'name': 'Ali Hassan', 'playerUserIds': ['u2'], 'seed': 2},
  ],
  'players': [
    {'userId': 'u1', 'firstName': 'Omar', 'lastName': 'Salah'},
    {'userId': 'u2', 'firstName': 'Ali', 'lastName': 'Hassan'},
  ],
  'fixtures': const [],
  'standings': const [],
});

final _list = [_groupsDetail.tournament, _draftDetail.tournament];

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required Size size,
  required String locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clubTournamentsProvider.overrideWith((ref) async => _list),
        myTournamentsProvider.overrideWith((ref) async => _list),
        tournamentDetailProvider('t1').overrideWith(
          (ref) async => _groupsDetail,
        ),
        tournamentDetailProvider('t2').overrideWith(
          (ref) async => _draftDetail,
        ),
        myTournamentDetailProvider('t1').overrideWith(
          (ref) async => _groupsDetail,
        ),
        sportsProvider.overrideWith(
          (ref) async => const [LookupOption(id: 's1', name: 'Football')],
        ),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const sizes = {'phone': Size(375, 812), 'desktop': Size(1280, 800)};

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final locale in const ['ar', 'en']) {
      group('$sizeName / $locale', () {
        testWidgets('club list', (tester) async {
          await _pump(
            tester,
            const ClubTournamentsPage(),
            size: size,
            locale: locale,
          );
          expect(find.text('Winter Cup'), findsOneWidget);
          expect(find.text('Table tennis league'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('running groups tournament, every tab', (tester) async {
          await _pump(
            tester,
            const ClubTournamentDetailPage(tournamentId: 't1'),
            size: size,
            locale: locale,
          );
          final tabs = find.byType(Tab);
          expect(tabs, findsNWidgets(4));
          for (var i = 0; i < 4; i++) {
            await tester.tap(tabs.at(i));
            await tester.pumpAndSettle();
            final error = tester.takeException();
            // The whole diagnostic, so a layout overflow names its widget.
            if (error is FlutterError) debugPrint(error.toStringDeep());
            expect(error, isNull, reason: 'tab $i');
          }
        });

        testWidgets('draft league shows set-up and the generate button', (
          tester,
        ) async {
          await _pump(
            tester,
            const ClubTournamentDetailPage(tournamentId: 't2'),
            size: size,
            locale: locale,
          );
          expect(find.text('Omar Salah'), findsOneWidget);
          expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));
          expect(find.byIcon(Icons.shuffle), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('create form', (tester) async {
          await _pump(
            tester,
            const TournamentFormPage(),
            size: size,
            locale: locale,
          );
          expect(find.byType(ChoiceChip), findsWidgets);
          expect(tester.takeException(), isNull);
        });

        testWidgets('player portal list and detail', (tester) async {
          await _pump(
            tester,
            const MyTournamentsPage(),
            size: size,
            locale: locale,
          );
          expect(find.text('Winter Cup'), findsOneWidget);

          await _pump(
            tester,
            const MyTournamentDetailPage(tournamentId: 't1'),
            size: size,
            locale: locale,
          );
          expect(tester.takeException(), isNull);
        });
      });
    }
  }

  testWidgets('the player portal marks the viewer’s own matches', (
    tester,
  ) async {
    await _pump(
      tester,
      FixturesList(
        detail: _groupsDetail,
        highlightParticipantId: _groupsDetail.myParticipantId,
      ),
      size: const Size(375, 812),
      locale: 'en',
    );
    final cards = tester.widgetList<FixtureCard>(find.byType(FixtureCard));
    // p1 plays f1 and f3; f2 is someone else's.
    expect([for (final c in cards) c.highlight], [true, false, true]);
  });

  test('knockout rounds are named by how many are left', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(knockoutRoundLabel(l10n, 3, 3), 'Final');
    expect(knockoutRoundLabel(l10n, 2, 3), 'Semi-final');
    expect(knockoutRoundLabel(l10n, 1, 3), 'Quarter-final');
    expect(knockoutRoundLabel(l10n, 1, 4), 'Round of 16');
  });
}
