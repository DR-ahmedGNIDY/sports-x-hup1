import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../application/calendar_events_controller.dart';
import '../shared/event_detail_body.dart';

class EventDetailPageMobile extends ConsumerWidget {
  const EventDetailPageMobile({super.key, required this.eventId, required this.isClub});

  final String eventId;
  final bool isClub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(calendarEventProvider(eventId));
    return AppScaffoldMobile(
      onRefresh: () async => ref.invalidate(calendarEventProvider(eventId)),
      slivers: [
        SliverToBoxAdapter(
          child: eventAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorState(
              message: '$e',
              onRetry: () => ref.invalidate(calendarEventProvider(eventId)),
            ),
            data: (event) => EventDetailBody(event: event, isClub: isClub),
          ),
        ),
      ],
    );
  }
}
