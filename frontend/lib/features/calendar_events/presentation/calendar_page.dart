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
    final isClub = ref.watch(sessionControllerProvider).user?.role == UserRole.club;
    return ResponsiveLayout(
      desktop: (context) => CalendarPageDesktop(isClub: isClub),
      mobile: (context) => CalendarPageMobile(isClub: isClub),
    );
  }
}
