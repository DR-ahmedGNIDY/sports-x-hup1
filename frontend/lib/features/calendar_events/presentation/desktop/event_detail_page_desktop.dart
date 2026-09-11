import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/calendar_events_controller.dart';
import '../shared/event_detail_body.dart';

class EventDetailPageDesktop extends ConsumerWidget {
  const EventDetailPageDesktop({super.key, required this.eventId, required this.isClub});

  final String eventId;
  final bool isClub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(calendarEventProvider(eventId));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: eventAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                ErrorState(message: '$e', onRetry: () => ref.invalidate(calendarEventProvider(eventId))),
            data: (event) => EventDetailBody(event: event, isClub: isClub),
          ),
        ),
      ),
    );
  }
}
