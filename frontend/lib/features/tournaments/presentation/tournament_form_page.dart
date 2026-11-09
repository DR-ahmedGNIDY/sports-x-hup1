import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../player/application/lookup_providers.dart';
import '../data/tournaments_repository.dart';
import '../domain/tournament.dart';
import 'tournament_widgets.dart';

/// `/club/tournaments/new` and `/club/tournaments/:id/edit`.
///
/// Once the schedule exists the settings that shaped it are locked — the
/// server refuses them too — and only the name, dates, notes and
/// visibility stay editable.
class TournamentFormPage extends ConsumerStatefulWidget {
  const TournamentFormPage({super.key, this.tournamentId});

  final String? tournamentId;

  @override
  ConsumerState<TournamentFormPage> createState() => _TournamentFormPageState();
}

class _TournamentFormPageState extends ConsumerState<TournamentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ageGroup = TextEditingController();
  final _notes = TextEditingController();
  final _pointsPerSet = TextEditingController(text: '11');
  final _maxPoints = TextEditingController();
  final _win = TextEditingController(text: '3');
  final _draw = TextEditingController(text: '1');
  final _loss = TextEditingController(text: '0');
  final _groups = TextEditingController(text: '2');
  final _qualifiers = TextEditingController(text: '2');
  final _penalties = TextEditingController(text: '5');

  String? _sportId;
  String? _startDate;
  String? _endDate;
  var _type = ParticipantType.individual;
  var _format = TournamentFormat.league;
  var _drawMode = 'random';
  var _bySets = false;
  var _bestOf = 3;
  var _winByTwo = true;
  var _doubleRound = false;
  var _allowDraws = true;
  var _penaltiesEnabled = true;
  var _visible = true;

  bool _loaded = false;
  bool _locked = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.tournamentId != null;

  @override
  void dispose() {
    for (final c in [
      _name,
      _ageGroup,
      _notes,
      _pointsPerSet,
      _maxPoints,
      _win,
      _draw,
      _loss,
      _groups,
      _qualifiers,
      _penalties,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Tournament t) {
    _loaded = true;
    _locked = !t.isDraft;
    _name.text = t.name;
    _ageGroup.text = t.ageGroup;
    _notes.text = t.notes;
    _sportId = t.sportId;
    _startDate = t.startDate;
    _endDate = t.endDate;
    _type = t.participantType;
    _format = t.format;
    _drawMode = t.drawMode;
    _bySets = t.scoring.bySets;
    _bestOf = t.scoring.bestOf;
    _pointsPerSet.text = '${t.scoring.pointsPerSet}';
    _winByTwo = t.scoring.winByTwo;
    _maxPoints.text = t.scoring.maxPointsPerSet?.toString() ?? '';
    _win.text = '${t.league.winPoints}';
    _draw.text = '${t.league.drawPoints}';
    _loss.text = '${t.league.lossPoints}';
    _doubleRound = t.league.doubleRound;
    _allowDraws = t.league.allowDraws;
    _groups.text = '${t.groupsCount}';
    _qualifiers.text = '${t.qualifiersPerGroup}';
    _penaltiesEnabled = t.penaltiesEnabled;
    _penalties.text = '${t.penaltiesCount}';
    _visible = t.visibleToPlayers;
  }

  int _n(TextEditingController c, int fallback) =>
      int.tryParse(c.text.trim()) ?? fallback;

  Map<String, dynamic> _body() {
    final always = <String, dynamic>{
      'name': _name.text.trim(),
      'notes': _notes.text.trim(),
      'startDate': _startDate,
      'endDate': _endDate,
      'visibleToPlayers': _visible,
    };
    if (_locked) return always;
    final hasLeague = _format != TournamentFormat.knockout;
    final hasKnockout = _format != TournamentFormat.league;
    final maxPoints = int.tryParse(_maxPoints.text.trim());
    return {
      ...always,
      'sportId': _sportId,
      'ageGroup': _ageGroup.text.trim(),
      'participantType': _type.wireValue,
      'format': _format.wireValue,
      'drawMode': _drawMode,
      'scoring': {
        'mode': _bySets ? 'sets' : 'goals',
        if (_bySets) ...{
          'bestOf': _bestOf,
          'pointsPerSet': _n(_pointsPerSet, 11),
          'winByTwo': _winByTwo,
          'maxPointsPerSet': maxPoints,
        },
      },
      if (hasLeague)
        'league': {
          'winPoints': _n(_win, 3),
          'drawPoints': _n(_draw, 1),
          'lossPoints': _n(_loss, 0),
          'doubleRound': _doubleRound,
          'allowDraws': _allowDraws,
        },
      if (_format == TournamentFormat.groupsKnockout)
        'groups': {
          'count': _n(_groups, 2),
          'qualifiersPerGroup': _n(_qualifiers, 2),
        },
      if (hasKnockout && !_bySets)
        'knockout': {
          'penaltiesEnabled': _penaltiesEnabled,
          'penaltiesCount': _n(_penalties, 5),
        },
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = ref.read(tournamentsRepositoryProvider);
    try {
      if (_isEdit) {
        await repository.update(widget.tournamentId!, _body());
        ref.invalidate(tournamentDetailProvider(widget.tournamentId!));
        ref.invalidate(clubTournamentsProvider);
        if (mounted) context.pop();
      } else {
        final created = await repository.create(_body());
        ref.invalidate(clubTournamentsProvider);
        if (mounted) context.go('/club/tournaments/${created.id}');
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(bool start) async {
    final current = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null ? DateTime.parse(current) : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    setState(() => start ? _startDate = iso : _endDate = iso);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isEdit && !_loaded) {
      final detail = ref.watch(tournamentDetailProvider(widget.tournamentId!));
      return TournamentAsyncBody<TournamentDetail>(
        value: detail,
        onRetry: () =>
            ref.invalidate(tournamentDetailProvider(widget.tournamentId!)),
        builder: (d) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loaded) setState(() => _fill(d.tournament));
          });
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    final sports = ref.watch(sportsProvider).valueOrNull ?? const [];
    final digits = [FilteringTextInputFormatter.digitsOnly];
    final enabled = !_locked;
    final hasLeague = _format != TournamentFormat.knockout;
    final hasKnockout = _format != TournamentFormat.league;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );

    Widget number(TextEditingController c, String label) => TextFormField(
      controller: c,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: digits,
      decoration: InputDecoration(labelText: label),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              section(l10n.tournamentSectionBasics),
              TextFormField(
                controller: _name,
                maxLength: 150,
                decoration: InputDecoration(labelText: l10n.tournamentName),
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? l10n.tournamentName : null,
              ),
              DropdownButtonFormField<String?>(
                initialValue: _sportId,
                decoration: InputDecoration(labelText: l10n.tournamentSport),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.tournamentNoSport),
                  ),
                  for (final s in sports)
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: enabled ? (v) => setState(() => _sportId = v) : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageGroup,
                enabled: enabled,
                maxLength: 50,
                decoration: InputDecoration(labelText: l10n.tournamentAgeGroup),
              ),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: l10n.tournamentStartDate,
                      value: _startDate,
                      onTap: () => _pickDate(true),
                      onClear: () => setState(() => _startDate = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTile(
                      label: l10n.tournamentEndDate,
                      value: _endDate,
                      onTap: () => _pickDate(false),
                      onClear: () => setState(() => _endDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLength: 1000,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.tournamentNotes),
              ),

              section(l10n.tournamentSectionSystem),
              _Choice<ParticipantType>(
                label: l10n.tournamentType,
                enabled: enabled,
                value: _type,
                options: {
                  for (final t in ParticipantType.values)
                    t: participantTypeLabel(l10n, t),
                },
                onChanged: (v) => setState(() {
                  _type = v;
                  // Sets are for individual play only.
                  if (v == ParticipantType.team) _bySets = false;
                }),
              ),
              _Choice<TournamentFormat>(
                label: l10n.tournamentFormat,
                enabled: enabled,
                value: _format,
                options: {
                  for (final f in TournamentFormat.values)
                    f: tournamentFormatLabel(l10n, f),
                },
                onChanged: (v) => setState(() => _format = v),
              ),
              _Choice<String>(
                label: l10n.tournamentDrawMode,
                enabled: enabled,
                value: _drawMode,
                options: {
                  'random': l10n.tournamentDrawRandom,
                  'directed': l10n.tournamentDrawDirected,
                },
                onChanged: (v) => setState(() => _drawMode = v),
              ),
              if (_format == TournamentFormat.groupsKnockout)
                Row(
                  children: [
                    Expanded(
                      child: number(_groups, l10n.tournamentGroupsCount),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: number(_qualifiers, l10n.tournamentQualifiers),
                    ),
                  ],
                ),

              section(l10n.tournamentSectionScoring),
              _Choice<bool>(
                label: l10n.tournamentSectionScoring,
                enabled: enabled && _type == ParticipantType.individual,
                value: _bySets,
                options: {
                  false: l10n.tournamentScoringGoals,
                  true: l10n.tournamentScoringSets,
                },
                onChanged: (v) => setState(() => _bySets = v),
              ),
              if (_bySets) ...[
                _Choice<int>(
                  label: l10n.tournamentBestOf,
                  enabled: enabled,
                  value: _bestOf,
                  options: {
                    for (final n in const [1, 3, 5, 7])
                      n: l10n.tournamentBestOfValue(n),
                  },
                  onChanged: (v) => setState(() => _bestOf = v),
                ),
                Row(
                  children: [
                    Expanded(
                      child: number(_pointsPerSet, l10n.tournamentPointsPerSet),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: number(_maxPoints, l10n.tournamentMaxPoints),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tournamentWinByTwo),
                  value: _winByTwo,
                  onChanged: enabled
                      ? (v) => setState(() => _winByTwo = v)
                      : null,
                ),
              ],
              if (hasKnockout && !_bySets) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tournamentPenalties),
                  value: _penaltiesEnabled,
                  onChanged: enabled
                      ? (v) => setState(() => _penaltiesEnabled = v)
                      : null,
                ),
                if (_penaltiesEnabled)
                  number(_penalties, l10n.tournamentPenaltiesCount),
              ],

              if (hasLeague) ...[
                section(l10n.tournamentSectionLeague),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tournamentDoubleRound),
                  value: _doubleRound,
                  onChanged: enabled
                      ? (v) => setState(() => _doubleRound = v)
                      : null,
                ),
                if (!_bySets)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.tournamentAllowDraws),
                    value: _allowDraws,
                    onChanged: enabled
                        ? (v) => setState(() => _allowDraws = v)
                        : null,
                  ),
                Row(
                  children: [
                    Expanded(child: number(_win, l10n.tournamentWinPoints)),
                    const SizedBox(width: 12),
                    Expanded(child: number(_draw, l10n.tournamentDrawPoints)),
                    const SizedBox(width: 12),
                    Expanded(child: number(_loss, l10n.tournamentLossPoints)),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.tournamentVisibleToPlayers),
                value: _visible,
                onChanged: (v) => setState(() => _visible = v),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveLabel),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled row of choice chips.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in options.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: entry.key == value,
                onSelected: enabled ? (_) => onChanged(entry.key) : null,
              ),
          ],
        ),
      ],
    ),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: value == null
            ? const Icon(Icons.calendar_today_outlined, size: 18)
            : IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
              ),
      ),
      child: Text(value?.replaceAll('-', '/') ?? ''),
    ),
  );
}
