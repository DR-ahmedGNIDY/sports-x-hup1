import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../application/calendar_events_controller.dart';
import '../shared/day_events_sheet.dart';
import '../shared/month_calendar_grid.dart';

class CalendarPageMobile extends ConsumerStatefulWidget {
  const CalendarPageMobile({super.key, required this.isClub});

  final bool isClub;

  @override
  ConsumerState<CalendarPageMobile> createState() => _CalendarPageMobileState();
}

class _CalendarPageMobileState extends ConsumerState<CalendarPageMobile> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  String get _monthKey =>
      '${_visibleMonth.year}-${_visibleMonth.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final eventsAsync = widget.isClub
        ? ref.watch(calendarEventsProvider(_monthKey))
        : ref.watch(playerCalendarEventsProvider(_monthKey));
    final currentYear = DateTime.now().year;
    final availableBirthYears = [for (var y = currentYear; y >= currentYear - 25; y--) y];

    return AppScaffoldMobile(
      onRefresh: () async {
        ref.invalidate(
          widget.isClub
              ? calendarEventsProvider(_monthKey)
              : playerCalendarEventsProvider(_monthKey),
        );
      },
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(
                        () => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1),
                      ),
                    ),
                    Expanded(
                      child: Center(child: Text('${_visibleMonth.year}/${_visibleMonth.month}')),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(
                        () => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                eventsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => ErrorState(
                    message: '$e',
                    onRetry: () => ref.invalidate(
                      widget.isClub
                          ? calendarEventsProvider(_monthKey)
                          : playerCalendarEventsProvider(_monthKey),
                    ),
                  ),
                  data: (events) => MonthCalendarGrid(
                    month: _visibleMonth,
                    events: events,
                    onDayTap: (day) {
                      final dayEvents = events
                          .where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day)
                          .toList();
                      showDayEventsSheet(
                        context,
                        ref: ref,
                        day: day,
                        dayEvents: dayEvents,
                        isClub: widget.isClub,
                        availableBirthYears: availableBirthYears,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
