import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/calendar_event.dart';

String calendarEventTypeLabel(CalendarEventType type) => switch (type) {
  CalendarEventType.match => 'مباراة',
  CalendarEventType.training => 'تدريب',
  CalendarEventType.other => 'نشاط',
};

/// One event's card — the tapped day's list, and the club calendar's own
/// day sheet. Shows "أكمل التسجيل" until the roster has been confirmed.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.isClub,
    required this.onTap,
    this.onCompleteRegistration,
  });

  final CalendarEvent event;
  final bool isClub;
  final VoidCallback onTap;
  final VoidCallback? onCompleteRegistration;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
          child: Icon(_iconFor(event.type), color: AppColors.brandBlue),
        ),
        title: Text(event.displayName(typeLabel: calendarEventTypeLabel)),
        subtitle: Text('${event.startTime} - ${event.endTime}  •  ${event.location}'),
        trailing: isClub && !event.isConfirmed
            ? TextButton(
                onPressed: onCompleteRegistration,
                child: const Text('أكمل التسجيل'),
              )
            : null,
      ),
    );
  }

  IconData _iconFor(CalendarEventType type) => switch (type) {
    CalendarEventType.match => Icons.sports_soccer,
    CalendarEventType.training => Icons.fitness_center,
    CalendarEventType.other => Icons.event,
  };
}
