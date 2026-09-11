import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/entities/calendar_event.dart';

/// A hand-rolled month grid — this app has no calendar package dependency
/// and never reaches for one (`showDatePicker` covers every other
/// date-picking need). Platform-agnostic: desktop and mobile both use this
/// unchanged, differing only in the chrome around it.
class MonthCalendarGrid extends StatelessWidget {
  const MonthCalendarGrid({
    super.key,
    required this.month,
    required this.events,
    required this.onDayTap,
    this.selectedDay,
  });

  /// The first day of the visible month.
  final DateTime month;
  final List<CalendarEvent> events;
  final ValueChanged<DateTime> onDayTap;
  final DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first grid — 1 (Mon) .. 7 (Sun) becomes 0-based lead-in cells.
    final leadingBlanks = firstOfMonth.weekday - 1;

    final eventsByDay = <int, List<CalendarEvent>>{};
    for (final event in events) {
      if (event.date.year == month.year && event.date.month == month.month) {
        eventsByDay.putIfAbsent(event.date.day, () => []).add(event);
      }
    }

    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.greyLight.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          // 2024-01-01 was a Monday, so adding i walks the
                          // week in the same Monday-first order as the grid.
                          DateFormat.EEEE(
                            locale,
                          ).format(DateTime(2024, 1, 1 + i)),
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.greyLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 12,
            thickness: 1,
            color: AppColors.greyLight.withValues(alpha: 0.18),
          ),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  _buildCell(
                    context,
                    row * 7 + col,
                    leadingBlanks,
                    daysInMonth,
                    eventsByDay,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    int cellIndex,
    int leadingBlanks,
    int daysInMonth,
    Map<int, List<CalendarEvent>> eventsByDay,
  ) {
    final day = cellIndex - leadingBlanks + 1;
    if (day < 1 || day > daysInMonth) {
      return const Expanded(child: SizedBox(height: 52));
    }
    final date = DateTime(month.year, month.month, day);
    final dayEvents = eventsByDay[day] ?? const [];
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = selectedDay != null && _isSameDay(date, selectedDay!);
    final theme = Theme.of(context);

    final Color numberColor;
    if (isSelected) {
      numberColor = AppColors.white;
    } else if (isToday) {
      numberColor = AppColors.brandBlue;
    } else {
      numberColor = theme.textTheme.bodyMedium?.color ?? AppColors.white;
    }

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => onDayTap(date),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.brandBlue : null,
                  border: !isSelected && isToday
                      ? Border.all(color: AppColors.brandBlue, width: 1.4)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: numberColor,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 5,
                child: dayEvents.isEmpty
                    ? null
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < dayEvents.length && i < 3; i++)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.white
                                    : _dotColor(dayEvents[i].type),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A glance at the month should say what kind of week it is, not just that
  /// something is on.
  Color _dotColor(CalendarEventType type) => switch (type) {
    CalendarEventType.match => AppColors.brandBlue,
    CalendarEventType.training => AppColors.success,
    CalendarEventType.other => AppColors.warning,
  };

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
