import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_radius.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/tournament.dart';

String tournamentStatusLabel(AppLocalizations l10n, TournamentStatus s) =>
    switch (s) {
      TournamentStatus.draft => l10n.tournamentStatusDraft,
      TournamentStatus.running => l10n.tournamentStatusRunning,
      TournamentStatus.finished => l10n.tournamentStatusFinished,
    };

String tournamentFormatLabel(AppLocalizations l10n, TournamentFormat f) =>
    switch (f) {
      TournamentFormat.league => l10n.tournamentFormatLeague,
      TournamentFormat.knockout => l10n.tournamentFormatKnockout,
      TournamentFormat.groupsKnockout => l10n.tournamentFormatGroups,
    };

String participantTypeLabel(AppLocalizations l10n, ParticipantType t) =>
    switch (t) {
      ParticipantType.individual => l10n.tournamentTypeIndividual,
      ParticipantType.team => l10n.tournamentTypeTeam,
    };

/// A knockout round by how many are left in it: Final, Semi-final, …
String knockoutRoundLabel(AppLocalizations l10n, int round, int totalRounds) {
  final remaining = math.pow(2, totalRounds - round + 1).toInt();
  return switch (remaining) {
    2 => l10n.tournamentFinal,
    4 => l10n.tournamentSemiFinal,
    8 => l10n.tournamentQuarterFinal,
    _ => l10n.tournamentRoundOf(remaining),
  };
}

/// The heading a fixture is listed under.
String fixtureSectionLabel(
  AppLocalizations l10n,
  Fixture f,
  int knockoutRounds,
) {
  if (f.isKnockout) return knockoutRoundLabel(l10n, f.round, knockoutRounds);
  final round = l10n.tournamentRound(f.round);
  if (f.stage == 'group' && f.groupIndex != null) {
    return '${l10n.tournamentGroup(groupLetter(f.groupIndex!))} · $round';
  }
  return round;
}

int knockoutRoundsOf(List<Fixture> fixtures) => fixtures
    .where((f) => f.isKnockout)
    .fold(0, (m, f) => math.max(m, f.round));

class TournamentStatusChip extends StatelessWidget {
  const TournamentStatusChip({super.key, required this.status});

  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      TournamentStatus.draft => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      TournamentStatus.running => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      TournamentStatus.finished => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        tournamentStatusLabel(AppLocalizations.of(context)!, status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}

/// The shared loading / error shell.
class TournamentAsyncBody<T> extends StatelessWidget {
  const TournamentAsyncBody({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return value.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error is AppException && error.statusCode == 403
                    ? l10n.tournamentNoPermission
                    : error is AppException
                    ? error.message
                    : l10n.genericErrorMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(l10n.retryButtonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One side's name in a fixture, or "TBD" / "Bye" when there is none yet.
String sideName(
  AppLocalizations l10n,
  TournamentDetail detail,
  Fixture f,
  String? participantId,
) {
  final p = detail.participant(participantId);
  if (p != null) return p.name;
  return f.isBye ? l10n.tournamentBye : l10n.tournamentTbd;
}

/// The score line: "2 – 1", "2 – 2 (4 – 3)", or the sets for a sets match.
String? scoreLine(Fixture f) {
  if (!f.isPlayed) return null;
  final main = '${f.scoreA ?? 0} – ${f.scoreB ?? 0}';
  if (f.sets.isNotEmpty) {
    return '$main  (${f.sets.map((s) => '${s.a}-${s.b}').join(', ')})';
  }
  if (f.penaltiesA != null && f.penaltiesB != null) {
    return '$main  (${f.penaltiesA} – ${f.penaltiesB})';
  }
  return main;
}

/// A match row. [highlight] marks the viewer's own matches in the portal.
class FixtureCard extends StatelessWidget {
  const FixtureCard({
    super.key,
    required this.detail,
    required this.fixture,
    this.highlight = false,
    this.onTap,
  });

  final TournamentDetail detail;
  final Fixture fixture;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = fixture;
    final score = scoreLine(f);
    final when = [
      if (f.date != null) f.date!.replaceAll('-', '/'),
      if (f.time != null) f.time!,
      if (f.location.isNotEmpty) f.location,
    ].join(' · ');

    TextStyle? sideStyle(String? id) => f.winnerId != null && f.winnerId == id
        ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyLarge;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: highlight ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sideName(l10n, detail, f, f.aId),
                      style: sideStyle(f.aId),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      f.isBye ? l10n.tournamentBye : (score ?? '–'),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f.isBye ? '' : sideName(l10n, detail, f, f.bId),
                      textAlign: TextAlign.end,
                      style: sideStyle(f.bId),
                    ),
                  ),
                ],
              ),
              if (when.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    when,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every fixture grouped under its round heading.
class FixturesList extends StatelessWidget {
  const FixturesList({
    super.key,
    required this.detail,
    this.highlightParticipantId,
    this.onTap,
  });

  final TournamentDetail detail;
  final String? highlightParticipantId;
  final void Function(Fixture fixture)? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (detail.fixtures.isEmpty) {
      return Center(child: Text(l10n.tournamentNoSchedule));
    }
    final rounds = knockoutRoundsOf(detail.fixtures);
    final children = <Widget>[];
    String? last;
    for (final f in detail.fixtures) {
      final heading = fixtureSectionLabel(l10n, f, rounds);
      if (heading != last) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(
              heading,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        );
        last = heading;
      }
      children.add(
        FixtureCard(
          detail: detail,
          fixture: f,
          highlight: f.involves(highlightParticipantId),
          onTap: onTap == null ? null : () => onTap!(f),
        ),
      );
    }
    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}

/// The league table, or one table per group.
class StandingsView extends StatelessWidget {
  const StandingsView({
    super.key,
    required this.detail,
    this.highlightParticipantId,
  });

  final TournamentDetail detail;
  final String? highlightParticipantId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (detail.standings.isEmpty) {
      return Center(child: Text(l10n.tournamentNoSchedule));
    }
    DataCell num(int v) => DataCell(Text('$v'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final group in detail.standings) ...[
          if (group.groupIndex != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text(
                l10n.tournamentGroup(groupLetter(group.groupIndex!)),
                style: theme.textTheme.titleSmall,
              ),
            ),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: [
                  const DataColumn(label: Text('#')),
                  DataColumn(label: Text(l10n.tournamentTabParticipants)),
                  DataColumn(label: Text(l10n.tournamentPlayed), numeric: true),
                  DataColumn(label: Text(l10n.tournamentWon), numeric: true),
                  DataColumn(label: Text(l10n.tournamentDrawn), numeric: true),
                  DataColumn(label: Text(l10n.tournamentLost), numeric: true),
                  DataColumn(
                    label: Text(l10n.tournamentGoalDiff),
                    numeric: true,
                  ),
                  DataColumn(label: Text(l10n.tournamentPoints), numeric: true),
                ],
                rows: [
                  for (final row in group.rows)
                    DataRow(
                      color: row.id == highlightParticipantId
                          ? WidgetStatePropertyAll(
                              theme.colorScheme.primaryContainer,
                            )
                          : null,
                      cells: [
                        num(row.position),
                        DataCell(Text(detail.participant(row.id)?.name ?? '')),
                        num(row.played),
                        num(row.won),
                        num(row.drawn),
                        num(row.lost),
                        DataCell(
                          Text(row.diff > 0 ? '+${row.diff}' : '${row.diff}'),
                        ),
                        DataCell(
                          Text(
                            '${row.points}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// The knockout bracket as columns, one per round, scrolling sideways.
class BracketView extends StatelessWidget {
  const BracketView({
    super.key,
    required this.detail,
    this.highlightParticipantId,
    this.onTap,
  });

  final TournamentDetail detail;
  final String? highlightParticipantId;
  final void Function(Fixture fixture)? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ko = detail.fixtures.where((f) => f.isKnockout).toList();
    if (ko.isEmpty) return Center(child: Text(l10n.tournamentNoSchedule));
    final rounds = knockoutRoundsOf(ko);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var r = 1; r <= rounds; r++)
            SizedBox(
              width: 240,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        knockoutRoundLabel(l10n, r, rounds),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    for (final f in ko.where((f) => f.round == r))
                      FixtureCard(
                        detail: detail,
                        fixture: f,
                        highlight: f.involves(highlightParticipantId),
                        onTap: onTap == null ? null : () => onTap!(f),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The participants with their players, the viewer's own marked.
class ParticipantsView extends StatelessWidget {
  const ParticipantsView({
    super.key,
    required this.detail,
    this.highlightParticipantId,
  });

  final TournamentDetail detail;
  final String? highlightParticipantId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final p in detail.participants)
          ParticipantTile(
            detail: detail,
            participant: p,
            highlight: p.id == highlightParticipantId,
          ),
      ],
    );
  }
}

class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    super.key,
    required this.detail,
    required this.participant,
    this.highlight = false,
    this.trailing,
    this.onTap,
  });

  final TournamentDetail detail;
  final Participant participant;
  final bool highlight;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isTeam =
        detail.tournament.participantType == ParticipantType.team;
    final members = participant.playerUserIds
        .map((id) {
          final name = detail.players[id]?.name ?? '';
          return id == participant.captainUserId
              ? '$name (${l10n.tournamentCaptain})'
              : name;
        })
        .where((n) => n.isNotEmpty)
        .join('، ');
    final photo = isTeam
        ? null
        : detail.players[participant.playerUserIds.firstOrNull]?.photoUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: highlight ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: photo == null ? null : NetworkImage(photo),
          child: photo == null
              ? Icon(isTeam ? Icons.groups_outlined : Icons.person_outline)
              : null,
        ),
        title: Text(participant.name),
        subtitle: isTeam && members.isNotEmpty ? Text(members) : null,
        trailing:
            trailing ??
            (participant.groupIndex != null
                ? Text(
                    l10n.tournamentGroup(groupLetter(participant.groupIndex!)),
                  )
                : null),
      ),
    );
  }
}
