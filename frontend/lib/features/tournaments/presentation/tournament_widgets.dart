import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../player/application/lookup_providers.dart';
import '../domain/tournament.dart';

// ------------------------------------------------------------------ labels

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

int knockoutRoundsOf(List<Fixture> fixtures) =>
    fixtures.where((f) => f.isKnockout).fold(0, (m, f) => math.max(m, f.round));

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

String _date(String iso) => iso.replaceAll('-', '/');

/// Matches that count towards progress: every one but the byes.
List<Fixture> _realFixtures(TournamentDetail d) =>
    d.fixtures.where((f) => !f.isBye).toList();

/// The next match still to play — the viewer's own when [participantId] is
/// given — earliest dated first, then in schedule order.
Fixture? nextFixture(TournamentDetail d, {String? participantId}) {
  final pending = d.fixtures
      .where(
        (f) =>
            f.status == 'pending' &&
            f.aId != null &&
            f.bId != null &&
            (participantId == null || f.involves(participantId)),
      )
      .toList();
  if (pending.isEmpty) return null;
  String key(Fixture f) => '${f.date ?? '9999'} ${f.time ?? '99:99'}';
  pending.sort((a, b) => key(a).compareTo(key(b)));
  return pending.first;
}

/// Last results of [participantId] outside the knockout stage, oldest
/// first, at most five: 'W', 'D' or 'L'.
List<String> formOf(TournamentDetail d, String participantId) {
  final played =
      d.fixtures
          .where(
            (f) => !f.isKnockout && f.isPlayed && f.involves(participantId),
          )
          .toList()
        ..sort((a, b) => a.round.compareTo(b.round));
  final recent = played.length > 5 ? played.sublist(played.length - 5) : played;
  return [
    for (final f in recent)
      f.winnerId == null
          ? 'D'
          : f.winnerId == participantId
          ? 'W'
          : 'L',
  ];
}

// ----------------------------------------------------------------- shells

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
      TournamentStatus.running => (scheme.primary, scheme.onPrimary),
      TournamentStatus.finished => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
    };
    return _Pill(
      text: tournamentStatusLabel(AppLocalizations.of(context)!, status),
      background: bg,
      foreground: fg,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
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

// ------------------------------------------------------------- team badge

const _badgePalette = <(Color, Color)>[
  (Color(0xFFBFD8FF), Color(0xFF0B2E66)),
  (Color(0xFFF5D38A), Color(0xFF3D2A00)),
  (Color(0xFFD6C2F0), Color(0xFF2B1A45)),
  (Color(0xFFF7C6C0), Color(0xFF4A1712)),
  (Color(0xFFBFE3F5), Color(0xFF0E3346)),
  (Color(0xFFC8E6C0), Color(0xFF1F3A18)),
  (Color(0xFFE7E2C6), Color(0xFF3A3412)),
  (Color(0xFFB9C3D6), Color(0xFF1B2333)),
];

/// A side's mark: the player's photo, or the team's initial on a colour
/// that is always the same for that name.
class TeamBadge extends StatelessWidget {
  const TeamBadge({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 36,
  });

  final String name;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final trimmed = name.trim();
    final (bg, fg) =
        _badgePalette[trimmed.codeUnits.fold(0, (a, b) => a + b) %
            _badgePalette.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        image: url == null
            ? null
            : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: url != null
          ? null
          : Text(
              trimmed.isEmpty ? '?' : trimmed.characters.first,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.42,
              ),
            ),
    );
  }
}

/// The badge for a participant: a single player's photo when there is one.
TeamBadge badgeFor(
  TournamentDetail d,
  String? participantId, {
  double size = 36,
}) {
  final p = d.participant(participantId);
  final photo =
      p != null && d.tournament.participantType == ParticipantType.individual
      ? d.players[p.playerUserIds.firstOrNull]?.photoUrl
      : null;
  return TeamBadge(name: p?.name ?? '', photoUrl: photo, size: size);
}

// ----------------------------------------------------------------- header

/// The app's name for [sportId], once the sports list has loaded.
String? sportName(WidgetRef ref, String? sportId) {
  if (sportId == null) return null;
  final sports = ref.watch(sportsProvider).valueOrNull ?? const [];
  for (final s in sports) {
    if (s.id == sportId) return s.name;
  }
  return null;
}

/// The tabs, on the same dark band as the header above them.
class TournamentTabBar extends StatelessWidget {
  const TournamentTabBar({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.black,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: scheme.primary,
        unselectedLabelColor: const Color(0xFF98A1B3),
        indicatorColor: scheme.primary,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        tabs: [for (final label in labels) Tab(text: label)],
      ),
    );
  }
}

/// The dark block at the top of a tournament: what it is, where it stands,
/// and how far along it is.
class TournamentHeader extends StatelessWidget {
  const TournamentHeader({
    super.key,
    required this.detail,
    this.sportName,
    this.trailing,
  });

  final TournamentDetail detail;
  final String? sportName;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = detail.tournament;
    const muted = Color(0xFF98A1B3);
    final real = _realFixtures(detail);
    final played = real.where((f) => f.isPlayed).length;
    final meta = [
      ?sportName,
      if (t.ageGroup.isNotEmpty) t.ageGroup,
    ].join(' · ');
    final info = [
      tournamentFormatLabel(l10n, t.format),
      l10n.tournamentParticipantsCount(detail.participants.length),
      if (t.startDate != null)
        [
          _date(t.startDate!),
          if (t.endDate != null) _date(t.endDate!),
        ].join(' – '),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 8, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meta,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
              TournamentStatusChip(status: t.status),
              ?trailing,
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Text(
              t.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final part in info)
                Text(
                  part,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFC9D0DB),
                  ),
                ),
            ],
          ),
          if (real.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tournamentProgress,
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  ),
                  Text(
                    l10n.tournamentMatchesPlayed(played, real.length),
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: played / real.length,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF26302E),
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The match coming up next — the viewer's own, in the portal.
class NextMatchCard extends StatelessWidget {
  const NextMatchCard({
    super.key,
    required this.detail,
    required this.fixture,
    this.mine = false,
  });

  final TournamentDetail detail;
  final Fixture fixture;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = fixture;
    const muted = Color(0xFF98A1B3);
    final rounds = knockoutRoundsOf(detail.fixtures);

    Widget side(String? id) => Expanded(
      child: Column(
        children: [
          badgeFor(detail, id, size: 52),
          const SizedBox(height: 6),
          Text(
            sideName(l10n, detail, f, id),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111A19),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mine
                      ? l10n.tournamentYourNextMatch
                      : l10n.tournamentNextMatch,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                fixtureSectionLabel(l10n, f, rounds),
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              side(f.aId),
              Column(
                children: [
                  Text(
                    f.time ?? '–',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (f.date != null)
                    Text(
                      _date(f.date!),
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                ],
              ),
              side(f.bId),
            ],
          ),
          if (f.location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.place_outlined, size: 14, color: muted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    f.location,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFC9D0DB),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- matches

/// A match: both sides with their badges, the score large, the winner in
/// bold with a tick, and the status. [highlight] marks the viewer's own.
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
    final scheme = theme.colorScheme;
    final f = fixture;
    final when = [
      if (f.date != null) _date(f.date!),
      ?f.time,
      if (f.location.isNotEmpty) f.location,
    ].join(' · ');
    final extra = f.sets.isNotEmpty
        ? f.sets.map((s) => '${s.a}-${s.b}').join('  ·  ')
        : f.penaltiesA != null && f.penaltiesB != null
        ? '${l10n.tournamentPenaltiesShort} ${f.penaltiesA} – ${f.penaltiesB}'
        : null;

    Widget side(String? id, int? score) {
      final won = f.isPlayed && f.winnerId != null && f.winnerId == id;
      final lost = f.isPlayed && f.winnerId != null && f.winnerId != id;
      final color = lost ? scheme.onSurfaceVariant : scheme.onSurface;
      return Row(
        children: [
          badgeFor(detail, id, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sideName(l10n, detail, f, id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: won ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          if (won)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Icon(Icons.check, size: 18, color: scheme.primary),
            ),
          SizedBox(
            width: 32,
            child: Text(
              f.isPlayed ? '${score ?? 0}' : '–',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: f.isPlayed ? color : scheme.outline,
                fontWeight: won ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    final status = f.isBye
        ? _Pill(
            text: l10n.tournamentBye,
            background: scheme.surfaceContainerHighest,
            foreground: scheme.onSurfaceVariant,
          )
        : f.isPlayed
        ? _Pill(
            text: l10n.tournamentMatchPlayed,
            background: scheme.primaryContainer,
            foreground: scheme.onPrimaryContainer,
          )
        : _Pill(
            text: l10n.tournamentMatchUpcoming,
            background: scheme.tertiaryContainer,
            foreground: scheme.onTertiaryContainer,
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: highlight
          ? scheme.primaryContainer.withValues(alpha: 0.35)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: highlight ? scheme.primary : scheme.outlineVariant,
          width: highlight ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      when,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  status,
                ],
              ),
              const SizedBox(height: 10),
              side(f.aId, f.scoreA),
              if (!f.isBye) ...[
                const SizedBox(height: 8),
                side(f.bId, f.scoreB),
              ],
              if (extra != null && f.isPlayed) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: scheme.outlineVariant),
                const SizedBox(height: 6),
                Text(
                  extra,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _FixtureFilter { all, upcoming, finished, mine }

/// The schedule: the next match on top, filter chips, then every match
/// under its round heading.
class FixturesList extends StatefulWidget {
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
  State<FixturesList> createState() => _FixturesListState();
}

class _FixturesListState extends State<FixturesList> {
  var _filter = _FixtureFilter.all;

  bool _keep(Fixture f) => switch (_filter) {
    _FixtureFilter.all => true,
    _FixtureFilter.upcoming => f.status == 'pending',
    _FixtureFilter.finished => f.isPlayed,
    _FixtureFilter.mine => f.involves(widget.highlightParticipantId),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detail = widget.detail;
    if (detail.fixtures.isEmpty) {
      return Center(child: Text(l10n.tournamentNoSchedule));
    }
    final mineId = widget.highlightParticipantId;
    final next = nextFixture(detail, participantId: mineId);
    final rounds = knockoutRoundsOf(detail.fixtures);
    final filters = {
      _FixtureFilter.all: l10n.tournamentFilterAll,
      _FixtureFilter.upcoming: l10n.tournamentFilterUpcoming,
      _FixtureFilter.finished: l10n.tournamentFilterFinished,
      if (mineId != null) _FixtureFilter.mine: l10n.tournamentFilterMine,
    };

    final children = <Widget>[
      if (next != null) ...[
        NextMatchCard(detail: detail, fixture: next, mine: mineId != null),
        const SizedBox(height: 14),
      ],
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in filters.entries)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: _filter == entry.key,
                  onSelected: (_) => setState(() => _filter = entry.key),
                ),
              ),
          ],
        ),
      ),
    ];

    final shown = detail.fixtures.where(_keep).toList();
    if (shown.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(child: Text(l10n.tournamentNoMatchesHere)),
        ),
      );
    }
    String? last;
    for (final f in shown) {
      final heading = fixtureSectionLabel(l10n, f, rounds);
      if (heading != last) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
            child: Text(
              heading,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
        last = heading;
      }
      children.add(
        FixtureCard(
          detail: detail,
          fixture: f,
          highlight: f.involves(mineId),
          onTap: widget.onTap == null ? null : () => widget.onTap!(f),
        ),
      );
    }
    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}

// -------------------------------------------------------------- standings

/// The table: position, side with recent form, played, difference and
/// points — qualifiers marked, a tapped row opening its full record.
class StandingsView extends StatefulWidget {
  const StandingsView({
    super.key,
    required this.detail,
    this.highlightParticipantId,
  });

  final TournamentDetail detail;
  final String? highlightParticipantId;

  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = widget.detail;
    if (detail.standings.isEmpty) {
      return Center(child: Text(l10n.tournamentNoSchedule));
    }
    final t = detail.tournament;
    final qualifiers = t.format == TournamentFormat.groupsKnockout
        ? t.qualifiersPerGroup
        : 0;
    final headStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    Widget cell(String text, {double width = 36, TextStyle? style}) => SizedBox(
      width: width,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );

    Widget formChip(String result) {
      final (bg, label) = switch (result) {
        'W' => (scheme.primary, l10n.tournamentFormWin),
        'L' => (const Color(0xFFC2410C), l10n.tournamentFormLoss),
        _ => (const Color(0xFF6B7280), l10n.tournamentFormDraw),
      };
      return Container(
        width: 18,
        height: 18,
        margin: const EdgeInsetsDirectional.only(end: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.xxs),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: result == 'W' ? scheme.onPrimary : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    Widget row(StandingRow r) {
      final qualifies = r.position <= qualifiers;
      final mine = r.id == widget.highlightParticipantId;
      final name = detail.participant(r.id)?.name ?? '';
      final form = formOf(detail, r.id);
      final expanded = _expanded == r.id;
      return Material(
        color: mine
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = expanded ? null : r.id),
          child: Container(
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(
                  color: qualifies ? scheme.primary : Colors.transparent,
                  width: 4,
                ),
                bottom: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: qualifies
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${r.position}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: qualifies
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              badgeFor(detail, r.id, size: 26),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: mine || qualifies
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (mine) ...[
                                const SizedBox(width: 6),
                                _Pill(
                                  text: l10n.tournamentYourTeam,
                                  background: AppColors.black,
                                  foreground: AppColors.white,
                                ),
                              ],
                            ],
                          ),
                          if (form.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(children: [for (final x in form) formChip(x)]),
                          ],
                        ],
                      ),
                    ),
                    cell('${r.played}'),
                    cell(
                      r.diff > 0 ? '+${r.diff}' : '${r.diff}',
                      width: 40,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: r.diff > 0
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    cell(
                      '${r.points}',
                      width: 44,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final (value, label) in [
                        (r.won, l10n.tournamentWon),
                        (r.drawn, l10n.tournamentDrawn),
                        (r.lost, l10n.tournamentLost),
                        (r.scored, l10n.tournamentScoredFor),
                        (r.conceded, l10n.tournamentScoredAgainst),
                      ])
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '$value',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(label, style: headStyle),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final group in detail.standings) ...[
          if (group.groupIndex != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
              child: Text(
                l10n.tournamentGroup(groupLetter(group.groupIndex!)),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                Container(
                  color: scheme.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      cell('#', style: headStyle),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.tournamentTeamColumn,
                          style: headStyle,
                        ),
                      ),
                      cell(l10n.tournamentPlayed, style: headStyle),
                      cell(
                        l10n.tournamentGoalDiff,
                        width: 40,
                        style: headStyle,
                      ),
                      cell(
                        l10n.tournamentPoints,
                        width: 44,
                        style: headStyle?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final r in group.rows) row(r),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (qualifiers > 0)
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xxs),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.tournamentQualifies, style: headStyle),
              ),
            ],
          ),
        const SizedBox(height: 6),
        Text(l10n.tournamentTieBreakNote, style: headStyle),
      ],
    );
  }
}

// ---------------------------------------------------------------- bracket

const _cardW = 200.0;
const _cardH = 76.0;
const _gapV = 22.0;
const _colGap = 52.0;
const _top = 36.0;

/// The knockout stage as a real tree: every match joined to the one its
/// winner goes on to, the champion at the end, pannable and zoomable.
/// Tapping a side traces that side's path through the bracket.
class BracketView extends StatefulWidget {
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
  State<BracketView> createState() => _BracketViewState();
}

class _BracketViewState extends State<BracketView> {
  late String? _traced = widget.highlightParticipantId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = widget.detail;
    final ko = detail.fixtures.where((f) => f.isKnockout).toList();
    if (ko.isEmpty) return Center(child: Text(l10n.tournamentNoSchedule));

    final rounds = knockoutRoundsOf(ko);
    final firstRound = math.max(1, ko.where((f) => f.round == 1).length);
    const slot = _cardH + _gapV;
    double centerY(int round, int matchNo) =>
        _top + slot * math.pow(2, round - 1) * (matchNo - 0.5);
    double startX(int round) => (round - 1) * (_cardW + _colGap);
    final width = (rounds + 1) * (_cardW + _colGap);
    final height = math.max(_top + slot * firstRound + 12, _top + 160);

    final finalMatch = ko.where((f) => f.round == rounds).firstOrNull;
    final champion = finalMatch != null && finalMatch.isPlayed
        ? finalMatch.winnerId
        : null;
    final finalY = centerY(rounds, 1);

    final links = <_Link>[
      for (final f in ko)
        if (f.nextMatchNo != null)
          _Link(
            fromX: startX(f.round) + _cardW,
            fromY: centerY(f.round, f.matchNo),
            toX: startX(f.round + 1),
            toY: centerY(f.round + 1, f.nextMatchNo!),
            onPath: _traced != null && f.winnerId == _traced,
            played: f.isPlayed || f.isBye,
          ),
      if (finalMatch != null)
        _Link(
          fromX: startX(rounds) + _cardW,
          fromY: finalY,
          toX: startX(rounds + 1),
          toY: finalY,
          onPath: _traced != null && champion == _traced,
          played: finalMatch.isPlayed,
        ),
    ];

    Widget heading(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.onSurfaceVariant,
      ),
    );

    final tree = SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _LinksPainter(
                links: links,
                rtl: Directionality.of(context) == TextDirection.rtl,
                width: width,
                pathColor: scheme.primary,
                idleColor: scheme.outlineVariant,
              ),
            ),
          ),
          for (var r = 1; r <= rounds; r++)
            PositionedDirectional(
              start: startX(r),
              top: 4,
              width: _cardW,
              child: heading(knockoutRoundLabel(l10n, r, rounds)),
            ),
          PositionedDirectional(
            start: startX(rounds + 1),
            top: 4,
            width: _cardW,
            child: heading(l10n.tournamentChampion),
          ),
          for (final f in ko)
            PositionedDirectional(
              start: startX(f.round),
              top: centerY(f.round, f.matchNo) - _cardH / 2,
              width: _cardW,
              height: _cardH,
              child: _BracketCard(
                detail: detail,
                fixture: f,
                traced: _traced,
                onTrace: (id) =>
                    setState(() => _traced = _traced == id ? null : id),
                onEdit: widget.onTap == null ? null : () => widget.onTap!(f),
              ),
            ),
          PositionedDirectional(
            start: startX(rounds + 1),
            top: finalY - 70,
            width: _cardW,
            height: 140,
            child: _ChampionCard(detail: detail, championId: champion),
          ),
        ],
      ),
    );

    final traced = detail.participant(_traced);
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.5,
            maxScale: 2,
            boundaryMargin: const EdgeInsets.all(48),
            child: Padding(padding: const EdgeInsets.all(16), child: tree),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Wrap(
            spacing: 18,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (traced != null)
                _LegendLine(
                  color: scheme.primary,
                  label: l10n.tournamentPathOf(traced.name),
                ),
              _LegendLine(
                color: scheme.outline,
                label: l10n.tournamentNotPlayedYet,
                dashed: true,
              ),
              Text(
                l10n.tournamentPanHint,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BracketCard extends StatelessWidget {
  const _BracketCard({
    required this.detail,
    required this.fixture,
    required this.traced,
    required this.onTrace,
    this.onEdit,
  });

  final TournamentDetail detail;
  final Fixture fixture;
  final String? traced;
  final ValueChanged<String> onTrace;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = Theme.of(context);
    final f = fixture;
    final onPath = f.involves(traced);
    final dark = onPath && f.status == 'pending';
    // An upcoming match on the traced path is drawn dark, like the "next
    // match" card; its text colours follow.
    final theme = dark
        ? base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              surface: AppColors.black,
              onSurface: AppColors.white,
              onSurfaceVariant: const Color(0xFFC9D0DB),
            ),
          )
        : base;
    final scheme = theme.colorScheme;

    Widget side(String? id, int? score, int? pens) {
      final won = f.isPlayed && f.winnerId == id;
      final lost = f.isPlayed && f.winnerId != null && f.winnerId != id;
      final text = Row(
        children: [
          badgeFor(detail, id, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sideName(l10n, detail, f, id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: won ? FontWeight.w800 : FontWeight.w500,
                color: lost || id == null
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ),
            ),
          ),
          if (f.isPlayed)
            Text(
              pens != null ? '${score ?? 0} ($pens)' : '${score ?? 0}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: won ? FontWeight.w800 : FontWeight.w500,
                color: scheme.onSurface,
              ),
            )
          else if (f.time != null && id == f.aId)
            Text(
              f.time!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      );
      return id == null ? text : InkWell(onTap: () => onTrace(id), child: text);
    }

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: onPath ? base.colorScheme.primary : scheme.outlineVariant,
          width: onPath ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 4, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  side(f.aId, f.scoreA, f.penaltiesA),
                  if (!f.isBye) side(f.bId, f.scoreB, f.penaltiesB),
                ],
              ),
            ),
            if (onEdit != null && !f.isBye)
              IconButton(
                tooltip: l10n.tournamentRecordResult,
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                color: scheme.onSurfaceVariant,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChampionCard extends StatelessWidget {
  const _ChampionCard({required this.detail, required this.championId});

  final TournamentDetail detail;
  final String? championId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final champion = detail.participant(championId);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 40,
            color: AppColors.profileGold,
          ),
          const SizedBox(height: 6),
          if (champion != null) ...[
            badgeFor(detail, champion.id, size: 28),
            const SizedBox(height: 4),
            Text(
              champion.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ] else
            Text(
              l10n.tournamentChampionTbd,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFFC9D0DB),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 24,
        height: 4,
        child: CustomPaint(
          painter: _LinksPainter(
            links: [
              _Link(
                fromX: 0,
                fromY: 2,
                toX: 24,
                toY: 2,
                onPath: !dashed,
                played: !dashed,
              ),
            ],
            rtl: false,
            width: 24,
            pathColor: color,
            idleColor: color,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

/// One connector, in start-to-end coordinates.
class _Link {
  const _Link({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    required this.onPath,
    required this.played,
  });

  final double fromX;
  final double fromY;
  final double toX;
  final double toY;
  final bool onPath;
  final bool played;
}

/// Elbow connectors between rounds, mirrored for right-to-left. A link not
/// played yet is dashed; traced links are drawn last, so they sit on top
/// of the grey ones they share a segment with.
class _LinksPainter extends CustomPainter {
  _LinksPainter({
    required this.links,
    required this.rtl,
    required this.width,
    required this.pathColor,
    required this.idleColor,
  });

  final List<_Link> links;
  final bool rtl;
  final double width;
  final Color pathColor;
  final Color idleColor;

  double _x(double x) => rtl ? width - x : x;

  @override
  void paint(Canvas canvas, Size size) {
    final ordered = [
      ...links.where((l) => !l.onPath),
      ...links.where((l) => l.onPath),
    ];
    for (final l in ordered) {
      final paint = Paint()
        ..color = l.onPath ? pathColor : idleColor
        ..strokeWidth = l.onPath ? 3 : 2
        ..style = PaintingStyle.stroke;
      final midX = (l.fromX + l.toX) / 2;
      final points = [
        Offset(_x(l.fromX), l.fromY),
        Offset(_x(midX), l.fromY),
        Offset(_x(midX), l.toY),
        Offset(_x(l.toX), l.toY),
      ];
      for (var i = 0; i < points.length - 1; i++) {
        if (l.played || l.onPath) {
          canvas.drawLine(points[i], points[i + 1], paint);
        } else {
          _dashed(canvas, points[i], points[i + 1], paint);
        }
      }
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += 9) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, total), paint);
    }
  }

  @override
  bool shouldRepaint(_LinksPainter old) =>
      old.links != links ||
      old.rtl != rtl ||
      old.pathColor != pathColor ||
      old.idleColor != idleColor;
}

// ------------------------------------------------------------ participants

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
    final scheme = Theme.of(context).colorScheme;
    final isTeam = detail.tournament.participantType == ParticipantType.team;
    final members = participant.playerUserIds
        .map((id) {
          final name = detail.players[id]?.name ?? '';
          return id == participant.captainUserId
              ? '$name (${l10n.tournamentCaptain})'
              : name;
        })
        .where((n) => n.isNotEmpty)
        .join('، ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: highlight
          ? scheme.primaryContainer.withValues(alpha: 0.35)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: highlight ? scheme.primary : scheme.outlineVariant,
          width: highlight ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: badgeFor(detail, participant.id, size: 40),
        title: Text(
          participant.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
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
