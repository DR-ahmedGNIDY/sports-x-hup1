import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/entities/user_role.dart';
import 'desktop/calendar_page_desktop.dart';
import 'mobile/calendar_page_mobile.dart';

/// `/calendar` — a Club's own schedule, full read/write; a Player sees the
/// same screen read-only, scoped to the events they participate in (see
/// `CalendarEventsController` vs `PlayerCalendarEventsController`).
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A coach sees their active club's calendar; what they may change in it
    // is decided per action by their permissions (clubPermissionProvider).
    final role = ref.watch(sessionControllerProvider).user?.role;
    final isClub = role == UserRole.club || role == UserRole.coach;
    return ResponsiveLayout(
      desktop: (context) => CalendarPageDesktop(isClub: isClub),
      mobile: (context) => CalendarPageMobile(isClub: isClub),
    );
  }
}
