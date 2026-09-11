import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../player/domain/entities/football_position.dart';
import '../../application/calendar_events_controller.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/roster_pool.dart';

/// Step 2 of "أكمل التسجيل": each selected player, preloaded with the
/// primary position parsed from their own profile (via
/// [parseFootballPositions]/[formatFootballPositions]), editable via a
/// dropdown before confirming — the roster/position picker's own tap-to-
/// reassign interaction lives on the pitch itself (see
/// `event_lineup_pitch.dart`); this list is the fallback for a sport with no
/// pitch marker set, or a quick edit without opening the diagram.
Future<void> showPositionAssignmentSheet(
  BuildContext context, {
  required WidgetRef ref,
  required CalendarEvent event,
  required List<RosterPoolPlayer> players,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PositionAssignmentSheet(ref: ref, event: event, players: players),
  );
}

class _PositionAssignmentSheet extends StatefulWidget {
  const _PositionAssignmentSheet({
    required this.ref,
    required this.event,
    required this.players,
  });

  final WidgetRef ref;
  final CalendarEvent event;
  final List<RosterPoolPlayer> players;

  @override
  State<_PositionAssignmentSheet> createState() => _PositionAssignmentSheetState();
}

class _PositionAssignmentSheetState extends State<_PositionAssignmentSheet> {
  late final Map<String, String> _positions = {
    for (final player in widget.players)
      player.id: parseFootballPositions(player.position).firstOrNull ?? footballPositionCodes.first,
  };
  bool _submitting = false;

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    try {
      await widget.ref
          .read(calendarEventActionsProvider)
          .updateRoster(
            widget.event.id,
            playerIds: widget.players.map((p) => p.id).toList(),
            positions: _positions,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('تحديد المراكز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final player in widget.players)
                  ListTile(
                    title: Text(player.fullName.isEmpty ? player.id : player.fullName),
                    trailing: DropdownButton<String>(
                      value: _positions[player.id],
                      items: [
                        for (final code in footballPositionCodes)
                          DropdownMenuItem(value: code, child: Text(code)),
                      ],
                      onChanged: (value) => setState(() {
                        if (value != null) _positions[player.id] = value;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _confirm,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('تأكيد التشكيلة'),
          ),
        ],
      ),
    );
  }
}
