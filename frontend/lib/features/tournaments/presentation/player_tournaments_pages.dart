import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/tournaments_repository.dart';
import '../domain/tournament.dart';
import 'club_tournaments_pages.dart' show TournamentListTile;
import 'tournament_widgets.dart';

/// `/player/tournaments` — the club's published tournaments, read-only.
class MyTournamentsPage extends ConsumerWidget {
  const MyTournamentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentAsyncBody<List<Tournament>>(
      value: ref.watch(myTournamentsProvider),
      onRetry: () => ref.invalidate(myTournamentsProvider),
      builder: (items) => items.isEmpty
          ? Center(child: Text(l10n.myTournamentsEmpty))
          : RefreshIndicator(
              onRefresh: () => ref.refresh(myTournamentsProvider.future),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, i) => TournamentListTile(
                  tournament: items[i],
                  badge: items[i].isParticipant ? l10n.tournamentYouPlay : null,
                  onTap: () => context.go('/player/tournaments/${items[i].id}'),
                ),
              ),
            ),
    );
  }
}

/// `/player/tournaments/:id` — the viewer's own matches and team marked
/// throughout.
class MyTournamentDetailPage extends ConsumerWidget {
  const MyTournamentDetailPage({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentAsyncBody<TournamentDetail>(
      value: ref.watch(myTournamentDetailProvider(tournamentId)),
      onRetry: () => ref.invalidate(myTournamentDetailProvider(tournamentId)),
      builder: (detail) {
        final t = detail.tournament;
        final mine = detail.myParticipantId;
        final team = detail.participant(mine);
        final tabs = <(String, Widget)>[
          (
            l10n.tournamentTabFixtures,
            FixturesList(detail: detail, highlightParticipantId: mine),
          ),
          if (t.hasStandings)
            (
              l10n.tournamentTabStandings,
              StandingsView(detail: detail, highlightParticipantId: mine),
            ),
          if (t.hasBracket)
            (
              l10n.tournamentTabBracket,
              BracketView(detail: detail, highlightParticipantId: mine),
            ),
          (
            l10n.tournamentTabParticipants,
            ParticipantsView(detail: detail, highlightParticipantId: mine),
          ),
        ];
        return DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              TournamentHeader(
                detail: detail,
                sportName: [
                  ?sportName(ref, t.sportId),
                  if (team != null && t.participantType == ParticipantType.team)
                    '${l10n.tournamentYourTeam}: ${team.name}'
                  else if (team != null)
                    l10n.tournamentYouPlay,
                ].join(' · '),
              ),
              TournamentTabBar(labels: [for (final tab in tabs) tab.$1]),
              Expanded(
                child: TabBarView(children: [for (final tab in tabs) tab.$2]),
              ),
            ],
          ),
        );
      },
    );
  }
}
