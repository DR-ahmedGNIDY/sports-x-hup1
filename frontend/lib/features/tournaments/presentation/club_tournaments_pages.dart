import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/tournaments_repository.dart';
import '../domain/tournament.dart';
import 'tournament_widgets.dart';

void _snack(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

Future<bool> _confirm(BuildContext context, String message) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.deleteLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

// ------------------------------------------------------------------- list

/// `/club/tournaments`.
class ClubTournamentsPage extends ConsumerWidget {
  const ClubTournamentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/club/tournaments/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.tournamentNew),
      ),
      body: TournamentAsyncBody<List<Tournament>>(
        value: ref.watch(clubTournamentsProvider),
        onRetry: () => ref.invalidate(clubTournamentsProvider),
        builder: (items) => items.isEmpty
            ? Center(child: Text(l10n.tournamentsEmpty))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(clubTournamentsProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, i) => TournamentListTile(
                    tournament: items[i],
                    onTap: () => context.go('/club/tournaments/${items[i].id}'),
                  ),
                ),
              ),
      ),
    );
  }
}

class TournamentListTile extends StatelessWidget {
  const TournamentListTile({
    super.key,
    required this.tournament,
    required this.onTap,
    this.badge,
  });

  final Tournament tournament;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = tournament;
    final subtitle = [
      tournamentFormatLabel(l10n, t.format),
      participantTypeLabel(l10n, t.participantType),
      l10n.tournamentParticipantsCount(t.participantsCount),
      if (t.startDate != null) t.startDate!.replaceAll('-', '/'),
      ?badge,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.emoji_events_outlined),
        title: Text(t.name),
        subtitle: Text(subtitle),
        trailing: TournamentStatusChip(status: t.status),
        onTap: onTap,
      ),
    );
  }
}

// ----------------------------------------------------------------- detail

/// `/club/tournaments/:id` — set-up while in draft, then the schedule,
/// standings and bracket, every match tappable to schedule or score it.
class ClubTournamentDetailPage extends ConsumerWidget {
  const ClubTournamentDetailPage({super.key, required this.tournamentId});

  final String tournamentId;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      ref.invalidate(tournamentDetailProvider(tournamentId));
      ref.invalidate(clubTournamentsProvider);
    } on AppException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Read on use, not on build: a screen that is only looked at never
    // needs the repository (or the session behind it).
    TournamentsRepository repo() => ref.read(tournamentsRepositoryProvider);
    return TournamentAsyncBody<TournamentDetail>(
      value: ref.watch(tournamentDetailProvider(tournamentId)),
      onRetry: () => ref.invalidate(tournamentDetailProvider(tournamentId)),
      builder: (detail) {
        final t = detail.tournament;
        final tabs = <(String, Widget)>[
          (
            l10n.tournamentTabParticipants,
            _ParticipantsTab(
              detail: detail,
              onChanged: () {
                ref.invalidate(tournamentDetailProvider(tournamentId));
                ref.invalidate(clubTournamentsProvider);
              },
            ),
          ),
          if (!t.isDraft)
            (
              l10n.tournamentTabFixtures,
              FixturesList(
                detail: detail,
                onTap: (f) => _openFixture(context, ref, detail, f),
              ),
            ),
          if (!t.isDraft && t.hasStandings)
            (l10n.tournamentTabStandings, StandingsView(detail: detail)),
          if (!t.isDraft && t.hasBracket)
            (
              l10n.tournamentTabBracket,
              BracketView(
                detail: detail,
                onTap: (f) => _openFixture(context, ref, detail, f),
              ),
            ),
        ];

        return DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              TournamentHeader(
                detail: detail,
                sportName: sportName(ref, t.sportId),
                trailing: PopupMenuButton<String>(
                  iconColor: AppColors.white,
                  onSelected: (v) async {
                    switch (v) {
                      case 'edit':
                        context.go('/club/tournaments/${t.id}/edit');
                      case 'reset':
                        if (await _confirm(
                          context,
                          l10n.tournamentResetConfirm,
                        )) {
                          if (!context.mounted) return;
                          await _run(
                            context,
                            ref,
                            () => repo().resetSchedule(t.id),
                          );
                        }
                      case 'delete':
                        if (await _confirm(
                          context,
                          l10n.tournamentDeleteConfirm,
                        )) {
                          if (!context.mounted) return;
                          try {
                            await repo().delete(t.id);
                            ref.invalidate(clubTournamentsProvider);
                            if (context.mounted) {
                              context.go('/club/tournaments');
                            }
                          } on AppException catch (e) {
                            if (context.mounted) _snack(context, e.message);
                          }
                        }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(l10n.tournamentEdit),
                    ),
                    if (!t.isDraft && !detail.anyPlayed)
                      PopupMenuItem(
                        value: 'reset',
                        child: Text(l10n.tournamentResetSchedule),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.deleteLabel),
                    ),
                  ],
                ),
              ),
              if (t.isDraft)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.shuffle),
                      label: Text(l10n.tournamentGenerate),
                      onPressed: detail.participants.length < 2
                          ? null
                          : () =>
                                _run(context, ref, () => repo().generate(t.id)),
                    ),
                  ),
                ),
              if (tabs.length > 1)
                TournamentTabBar(labels: [for (final tab in tabs) tab.$1]),
              Expanded(
                child: tabs.length > 1
                    ? TabBarView(children: [for (final tab in tabs) tab.$2])
                    : tabs.first.$2,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFixture(
    BuildContext context,
    WidgetRef ref,
    TournamentDetail detail,
    Fixture f,
  ) async {
    if (f.isBye) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FixtureSheet(detail: detail, fixture: f),
    );
    ref.invalidate(tournamentDetailProvider(tournamentId));
    ref.invalidate(clubTournamentsProvider);
  }
}

// ------------------------------------------------------------ participants

class _ParticipantsTab extends ConsumerStatefulWidget {
  const _ParticipantsTab({required this.detail, required this.onChanged});

  final TournamentDetail detail;
  final VoidCallback onChanged;

  @override
  ConsumerState<_ParticipantsTab> createState() => _ParticipantsTabState();
}

class _ParticipantsTabState extends ConsumerState<_ParticipantsTab> {
  late List<Participant> _order = widget.detail.participants;

  @override
  void didUpdateWidget(covariant _ParticipantsTab old) {
    super.didUpdateWidget(old);
    _order = widget.detail.participants;
  }

  Future<void> _reorder(int from, int to) async {
    final next = [..._order];
    // onReorderItem already adjusts [to] for the removed item.
    next.insert(to, next.removeAt(from));
    setState(() => _order = next);
    try {
      await ref.read(tournamentsRepositoryProvider).orderParticipants(
        widget.detail.tournament.id,
        [for (final p in next) p.id],
      );
    } on AppException catch (e) {
      if (mounted) _snack(context, e.message);
    }
    widget.onChanged();
  }

  Future<void> _edit([Participant? existing]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          ParticipantSheet(detail: widget.detail, existing: existing),
    );
    widget.onChanged();
  }

  Future<void> _remove(Participant p) async {
    try {
      await ref
          .read(tournamentsRepositoryProvider)
          .removeParticipant(widget.detail.tournament.id, p.id);
    } on AppException catch (e) {
      if (mounted) _snack(context, e.message);
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = widget.detail.tournament;
    final isTeam = t.participantType == ParticipantType.team;
    final directed = t.isDraft && t.drawMode == 'directed';

    Widget tile(Participant p, int index) => ParticipantTile(
      key: ValueKey(p.id),
      detail: widget.detail,
      participant: p,
      onTap: isTeam ? () => _edit(p) : null,
      trailing: t.isDraft
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (directed) Text('#${index + 1}'),
                IconButton(
                  tooltip: l10n.deleteLabel,
                  icon: const Icon(Icons.close),
                  onPressed: () => _remove(p),
                ),
                if (directed)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
              ],
            )
          : null,
    );

    return Column(
      children: [
        if (t.isDraft)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    directed
                        ? l10n.tournamentDirectedHint
                        : (_order.length < 2 ? l10n.tournamentNeedTwo : ''),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(
                    isTeam
                        ? l10n.tournamentAddTeam
                        : l10n.tournamentAddParticipant,
                  ),
                  onPressed: () => _edit(),
                ),
              ],
            ),
          ),
        Expanded(
          child: directed
              ? ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: _order.length,
                  onReorderItem: _reorder,
                  itemBuilder: (_, i) => tile(_order[i], i),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (var i = 0; i < _order.length; i++) tile(_order[i], i),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Add an entry, or edit a team. An individual entry is one player and is
/// named after them; a team is a name, its players and an optional captain.
class ParticipantSheet extends ConsumerStatefulWidget {
  const ParticipantSheet({super.key, required this.detail, this.existing});

  final TournamentDetail detail;
  final Participant? existing;

  @override
  ConsumerState<ParticipantSheet> createState() => _ParticipantSheetState();
}

class _ParticipantSheetState extends ConsumerState<ParticipantSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final Set<String> _selected = {...?widget.existing?.playerUserIds};
  late String? _captain = widget.existing?.captainUserId;
  bool _saving = false;
  String? _error;

  bool get _isTeam =>
      widget.detail.tournament.participantType == ParticipantType.team;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(tournamentsRepositoryProvider);
    final id = widget.detail.tournament.id;
    final body = <String, dynamic>{
      'playerUserIds': _selected.toList(),
      if (_isTeam) 'name': _name.text.trim(),
      if (_isTeam) 'captainUserId': _captain,
    };
    try {
      final existing = widget.existing;
      if (existing == null) {
        await repo.addParticipant(id, body);
      } else {
        await repo.updateParticipant(id, existing.id, body);
      }
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final taken = {...widget.detail.enteredPlayerIds}
      ..removeAll(widget.existing?.playerUserIds ?? const []);
    final eligible = ref.watch(
      eligiblePlayersProvider(widget.detail.tournament.id),
    );
    final canSave =
        _selected.isNotEmpty &&
        (!_isTeam || _name.text.trim().isNotEmpty) &&
        !_saving;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing != null
                ? l10n.tournamentEditTeam
                : _isTeam
                ? l10n.tournamentAddTeam
                : l10n.tournamentAddParticipant,
            style: theme.textTheme.titleLarge,
          ),
          if (_isTeam) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              maxLength: 100,
              decoration: InputDecoration(labelText: l10n.tournamentTeamName),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 8),
          Text(l10n.tournamentPickPlayers, style: theme.textTheme.labelLarge),
          Flexible(
            child: TournamentAsyncBody<List<TournamentPlayer>>(
              value: eligible,
              onRetry: () => ref.invalidate(
                eligiblePlayersProvider(widget.detail.tournament.id),
              ),
              builder: (players) => ListView(
                shrinkWrap: true,
                children: [
                  for (final p in players)
                    _isTeam
                        ? CheckboxListTile(
                            value: _selected.contains(p.userId),
                            title: Text(p.name),
                            subtitle: taken.contains(p.userId)
                                ? Text(l10n.tournamentPlayerTaken)
                                : null,
                            onChanged: taken.contains(p.userId)
                                ? null
                                : (on) => setState(() {
                                    if (on == true) {
                                      _selected.add(p.userId);
                                    } else {
                                      _selected.remove(p.userId);
                                      if (_captain == p.userId) _captain = null;
                                    }
                                  }),
                          )
                        // One player per individual entry: a single choice.
                        : ListTile(
                            enabled: !taken.contains(p.userId),
                            leading: Icon(
                              _selected.contains(p.userId)
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                            ),
                            title: Text(p.name),
                            subtitle: taken.contains(p.userId)
                                ? Text(l10n.tournamentPlayerTaken)
                                : null,
                            onTap: () => setState(() {
                              _selected
                                ..clear()
                                ..add(p.userId);
                            }),
                          ),
                ],
              ),
            ),
          ),
          if (_isTeam && _selected.isNotEmpty)
            DropdownButtonFormField<String?>(
              // Keyed on the team, so a changed selection rebuilds the
              // field with a valid initial value.
              key: ValueKey(_selected.join(',')),
              initialValue: _selected.contains(_captain) ? _captain : null,
              decoration: InputDecoration(labelText: l10n.tournamentCaptain),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.tournamentNoCaptain),
                ),
                for (final id in _selected)
                  DropdownMenuItem(
                    value: id,
                    child: Text(
                      eligible.valueOrNull
                              ?.where((p) => p.userId == id)
                              .firstOrNull
                              ?.name ??
                          '',
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _captain = v),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: canSave ? _save : null,
            child: Text(l10n.saveLabel),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- fixture

/// One match: its date, time and place; its result (goals, sets or a
/// shoot-out, as the tournament scores); and — before any result is in —
/// swapping its two sides.
class FixtureSheet extends ConsumerStatefulWidget {
  const FixtureSheet({super.key, required this.detail, required this.fixture});

  final TournamentDetail detail;
  final Fixture fixture;

  @override
  ConsumerState<FixtureSheet> createState() => _FixtureSheetState();
}

class _FixtureSheetState extends ConsumerState<FixtureSheet> {
  late final Fixture f = widget.fixture;
  late final Tournament t = widget.detail.tournament;
  late final _location = TextEditingController(text: f.location);
  late final _scoreA = TextEditingController(text: f.scoreA?.toString() ?? '');
  late final _scoreB = TextEditingController(text: f.scoreB?.toString() ?? '');
  late final _penA = TextEditingController(
    text: f.penaltiesA?.toString() ?? '',
  );
  late final _penB = TextEditingController(
    text: f.penaltiesB?.toString() ?? '',
  );
  late final List<(TextEditingController, TextEditingController)> _sets = [
    for (final s in f.sets)
      (
        TextEditingController(text: '${s.a}'),
        TextEditingController(text: '${s.b}'),
      ),
    if (f.sets.isEmpty) (TextEditingController(), TextEditingController()),
  ];
  late String? _date = f.date;
  late String? _time = f.time;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_location, _scoreA, _scoreB, _penA, _penB]) {
      c.dispose();
    }
    for (final (a, b) in _sets) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  bool get _bothSides => f.aId != null && f.bId != null;
  bool get _canSwap =>
      f.status == 'pending' &&
      !widget.detail.anyPlayed &&
      !(f.isKnockout && f.round > 1) &&
      _bothSides;
  bool get _scoresLevel =>
      _scoreA.text.isNotEmpty && _scoreA.text == _scoreB.text;

  Future<void> _do(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _saveSchedule() => _do(
    () => ref.read(tournamentsRepositoryProvider).updateFixture(t.id, f.id, {
      'date': _date,
      'time': _time,
      'location': _location.text.trim(),
    }),
  );

  Future<void> _swap() => _do(
    () => ref.read(tournamentsRepositoryProvider).updateFixture(t.id, f.id, {
      'aId': f.bId,
      'bId': f.aId,
    }),
  );

  Future<void> _record() {
    final body = <String, dynamic>{};
    if (t.scoring.bySets) {
      body['sets'] = [
        for (final (a, b) in _sets)
          if (_int(a) != null && _int(b) != null) {'a': _int(a), 'b': _int(b)},
      ];
    } else {
      body['scoreA'] = _int(_scoreA);
      body['scoreB'] = _int(_scoreB);
      if (f.isKnockout && _scoresLevel) {
        body['penaltiesA'] = _int(_penA);
        body['penaltiesB'] = _int(_penB);
      }
    }
    return _do(
      () => ref
          .read(tournamentsRepositoryProvider)
          .recordResult(t.id, f.id, body),
    );
  }

  Future<void> _clear() => _do(
    () => ref.read(tournamentsRepositoryProvider).clearResult(t.id, f.id),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date != null ? DateTime.parse(_date!) : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(
      () => _date =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _pickTime() async {
    final parts = _time?.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: parts == null
          ? const TimeOfDay(hour: 18, minute: 0)
          : TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked == null) return;
    setState(
      () => _time =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final digits = [FilteringTextInputFormatter.digitsOnly];
    final a = sideName(l10n, widget.detail, f, f.aId);
    final b = sideName(l10n, widget.detail, f, f.bId);

    Widget box(TextEditingController c, String label) => SizedBox(
      width: 72,
      child: TextField(
        controller: c,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: digits,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() {}),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$a  ×  $b', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _date?.replaceAll('-', '/') ?? l10n.tournamentMatchDate,
                    ),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(_time ?? l10n.tournamentMatchTime),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            TextField(
              controller: _location,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: l10n.tournamentMatchLocation,
              ),
            ),
            Row(
              children: [
                if (_canSwap)
                  TextButton.icon(
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(l10n.tournamentSwapSides),
                    onPressed: _busy ? null : _swap,
                  ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _busy ? null : _saveSchedule,
                  child: Text(l10n.saveLabel),
                ),
              ],
            ),
            if (_bothSides) ...[
              const Divider(height: 32),
              Text(
                l10n.tournamentRecordResult,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (t.scoring.bySets) ...[
                for (var i = 0; i < _sets.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(l10n.tournamentSet(i + 1))),
                        box(_sets[i].$1, a),
                        const SizedBox(width: 12),
                        box(_sets[i].$2, b),
                      ],
                    ),
                  ),
                if (_sets.length < t.scoring.bestOf)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l10n.tournamentAddSet),
                      onPressed: () => setState(
                        () => _sets.add((
                          TextEditingController(),
                          TextEditingController(),
                        )),
                      ),
                    ),
                  ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    box(_scoreA, a),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('–'),
                    ),
                    box(_scoreB, b),
                  ],
                ),
                if (f.isKnockout && _scoresLevel && t.penaltiesEnabled) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.tournamentPenaltiesShort,
                    textAlign: TextAlign.center,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      box(_penA, a),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('–'),
                      ),
                      box(_penB, b),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (f.isPlayed)
                    TextButton(
                      onPressed: _busy ? null : _clear,
                      child: Text(l10n.tournamentClearResult),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _busy ? null : _record,
                    child: Text(l10n.tournamentRecordResult),
                  ),
                ],
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
