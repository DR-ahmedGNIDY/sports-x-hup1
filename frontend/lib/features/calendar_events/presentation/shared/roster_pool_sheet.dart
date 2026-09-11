import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/calendar_events_controller.dart';
import '../../domain/entities/calendar_event.dart';
import 'position_assignment_sheet.dart';

/// Step 1 of "أكمل التسجيل": checkboxes over the event's birth-year group
/// (or every managed player when the event was created for "all players"),
/// with a "select all" shortcut.
Future<void> showRosterPoolSheet(
  BuildContext context, {
  required WidgetRef ref,
  required CalendarEvent event,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) => _RosterPoolSheet(ref: ref, event: event),
  );
}

class _RosterPoolSheet extends ConsumerStatefulWidget {
  const _RosterPoolSheet({required this.ref, required this.event});

  final WidgetRef ref;
  final CalendarEvent event;

  @override
  ConsumerState<_RosterPoolSheet> createState() => _RosterPoolSheetState();
}

class _RosterPoolSheetState extends ConsumerState<_RosterPoolSheet> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final poolAsync = ref.watch(rosterPoolProvider(widget.event.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return poolAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (groups) {
            final allPlayers = [for (final g in groups) ...g.players];
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'اختيار اللاعبين',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          if (_selectedIds.length == allPlayers.length) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds
                              ..clear()
                              ..addAll(allPlayers.map((p) => p.id));
                          }
                        }),
                        child: Text(
                          _selectedIds.length == allPlayers.length ? 'إلغاء الكل' : 'تحديد الكل',
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        for (final group in groups) ...[
                          if (groups.length > 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                group.birthYear != null ? 'مواليد ${group.birthYear}' : 'غير محدد',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          for (final player in group.players)
                            CheckboxListTile(
                              value: _selectedIds.contains(player.id),
                              title: Text(player.fullName.isEmpty ? player.id : player.fullName),
                              subtitle: player.position != null ? Text(player.position!) : null,
                              onChanged: (checked) => setState(() {
                                if (checked ?? false) {
                                  _selectedIds.add(player.id);
                                } else {
                                  _selectedIds.remove(player.id);
                                }
                              }),
                            ),
                        ],
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            final selected = allPlayers
                                .where((p) => _selectedIds.contains(p.id))
                                .toList();
                            // Taken before the pop: this sheet's own context
                            // is defunct once it is gone, and the next sheet
                            // has to be presented from a live one.
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            navigator.pop();
                            showPositionAssignmentSheet(
                              navigator.context,
                              ref: widget.ref,
                              event: widget.event,
                              players: selected,
                            );
                          },
                    child: const Text('التالي'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
