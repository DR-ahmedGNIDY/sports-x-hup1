import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../player/domain/entities/football_position.dart';
import '../../application/calendar_events_controller.dart';
import '../../domain/entities/calendar_event.dart';

/// Per-participant match rating: goals/assists/chancesCreated/keyPasses/
/// keyDefensiveActions always, plus "saves" only when this participant's
/// *event* position resolves to GK via [parseFootballPositions] — there is
/// no schema enum for position anywhere in this codebase, so this free-text
/// check is the only mechanism available.
Future<void> showMatchStatSheet(
  BuildContext context, {
  required WidgetRef ref,
  required CalendarEvent event,
  required CalendarEventParticipant participant,
  required String participantName,
}) {
  final existing = event.matchStats.where((s) => s.playerId == participant.playerId).firstOrNull;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) => _MatchStatSheet(
      ref: ref,
      event: event,
      participant: participant,
      participantName: participantName,
      existing: existing,
    ),
  );
}

class _MatchStatSheet extends StatefulWidget {
  const _MatchStatSheet({
    required this.ref,
    required this.event,
    required this.participant,
    required this.participantName,
    this.existing,
  });

  final WidgetRef ref;
  final CalendarEvent event;
  final CalendarEventParticipant participant;
  final String participantName;
  final CalendarEventMatchStat? existing;

  @override
  State<_MatchStatSheet> createState() => _MatchStatSheetState();
}

class _MatchStatSheetState extends State<_MatchStatSheet> {
  late final _goals = TextEditingController(text: '${widget.existing?.goals ?? 0}');
  late final _assists = TextEditingController(text: '${widget.existing?.assists ?? 0}');
  late final _chancesCreated = TextEditingController(
    text: '${widget.existing?.chancesCreated ?? 0}',
  );
  late final _keyPasses = TextEditingController(text: '${widget.existing?.keyPasses ?? 0}');
  late final _keyDefensiveActions = TextEditingController(
    text: '${widget.existing?.keyDefensiveActions ?? 0}',
  );
  late final _saves = TextEditingController(text: '${widget.existing?.saves ?? 0}');
  bool _submitting = false;

  bool get _isGoalkeeper =>
      parseFootballPositions(widget.participant.position).contains('GK');

  int _parse(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    try {
      final entries = [
        for (final stat in widget.event.matchStats)
          if (stat.playerId != widget.participant.playerId) stat,
        CalendarEventMatchStat(
          playerId: widget.participant.playerId,
          goals: _parse(_goals),
          assists: _parse(_assists),
          chancesCreated: _parse(_chancesCreated),
          keyPasses: _parse(_keyPasses),
          keyDefensiveActions: _parse(_keyDefensiveActions),
          saves: _isGoalkeeper ? _parse(_saves) : 0,
        ),
      ];
      await widget.ref
          .read(calendarEventActionsProvider)
          .updateStats(widget.event.id, entries);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تقييم المباراة — ${widget.participantName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _field('الأهداف', _goals),
            _field('التمريرات الحاسمة', _assists),
            _field('الفرص التي صنعها', _chancesCreated),
            _field('التمريرات المفتاحية', _keyPasses),
            _field('الأفعال الدفاعية المهمة', _keyDefensiveActions),
            if (_isGoalkeeper) _field('التصديات', _saves),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _confirm,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ التقييم'),
            ),
          ],
        ),
      ),
    );
  }
}
