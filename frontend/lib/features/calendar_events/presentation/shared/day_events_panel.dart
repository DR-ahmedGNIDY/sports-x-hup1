import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/calendar_event.dart';
import 'create_event_sheet.dart';
import 'event_card.dart';
import 'roster_pool_sheet.dart';

/// The selected day's event cards, shown under the month grid rather than in
/// a sheet: [events] comes straight from the watched month provider, so an
/// event created from here appears the moment the month refetches instead of
/// hiding behind a sheet that captured the list before it existed.
class DayEventsPanel extends StatelessWidget {
  const DayEventsPanel({
    super.key,
    required this.ref,
    required this.day,
    required this.events,
    required this.isClub,
    required this.availableBirthYears,
  });

  final WidgetRef ref;
  final DateTime day;
  final List<CalendarEvent> events;
  final bool isClub;
  final List<int> availableBirthYears;

  @override
  Widget build(BuildContext context) {
    final dayEvents = [
      for (final event in events)
        if (event.date.year == day.year &&
            event.date.month == day.month &&
            event.date.day == day.day)
          event,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${day.year}/${day.month}/${day.day}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (dayEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('لا توجد أحداث في هذا اليوم'),
          ),
        for (final event in dayEvents)
          EventCard(
            event: event,
            isClub: isClub,
            onTap: () => context.push('/calendar/${event.id}'),
            onCompleteRegistration: () =>
                showRosterPoolSheet(context, ref: ref, event: event),
          ),
        if (isClub) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => showCreateEventSheet(
              context,
              ref: ref,
              day: day,
              availableBirthYears: availableBirthYears,
            ),
            icon: const Icon(Icons.add),
            label: const Text('إنشاء موعد جديد'),
          ),
        ],
      ],
    );
  }
}
