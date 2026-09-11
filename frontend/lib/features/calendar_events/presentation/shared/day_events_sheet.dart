import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/calendar_event.dart';
import 'create_event_sheet.dart';
import 'event_card.dart';
import 'roster_pool_sheet.dart';

/// The day a calendar cell resolves to: that day's events, plus (for a
/// club) a "New event" affordance.
Future<void> showDayEventsSheet(
  BuildContext context, {
  required WidgetRef ref,
  required DateTime day,
  required List<CalendarEvent> dayEvents,
  required bool isClub,
  required List<int> availableBirthYears,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${day.year}/${day.month}/${day.day}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (dayEvents.isEmpty) const Text('لا توجد أحداث في هذا اليوم'),
          for (final event in dayEvents)
            EventCard(
              event: event,
              isClub: isClub,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/calendar/${event.id}');
              },
              onCompleteRegistration: () {
                Navigator.of(context).pop();
                showRosterPoolSheet(context, ref: ref, event: event);
              },
            ),
          if (isClub) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showCreateEventSheet(
                  context,
                  ref: ref,
                  day: day,
                  availableBirthYears: availableBirthYears,
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('حدث جديد'),
            ),
          ],
        ],
      ),
    ),
  );
}
