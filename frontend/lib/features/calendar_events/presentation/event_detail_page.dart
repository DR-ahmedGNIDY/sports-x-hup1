import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/entities/user_role.dart';
import 'desktop/event_detail_page_desktop.dart';
import 'mobile/event_detail_page_mobile.dart';

/// `/calendar/:id` — full detail for the club that owns the event, and a
/// read-only view (no roster/stats controls) for a participating player.
class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClub = ref.watch(sessionControllerProvider).user?.role == UserRole.club;
    return ResponsiveLayout(
      desktop: (context) => EventDetailPageDesktop(eventId: eventId, isClub: isClub),
      mobile: (context) => EventDetailPageMobile(eventId: eventId, isClub: isClub),
    );
  }
}
