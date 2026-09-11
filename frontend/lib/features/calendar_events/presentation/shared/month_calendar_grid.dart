import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/calendar_event.dart';

/// A hand-rolled 7-column month grid — this app has no calendar package
/// dependency and never reaches for one (`showDatePicker` covers every other
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

  static const _weekdayLabels = ['اث', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];

  @override
  Widget build(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: AppColors.greyLight),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++) _buildCell(context, row * 7 + col, leadingBlanks, daysInMonth, eventsByDay),
            ],
          ),
      ],
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
      return const Expanded(child: SizedBox(height: 56));
    }
    final date = DateTime(month.year, month.month, day);
    final dayEvents = eventsByDay[day] ?? const [];
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = selectedDay != null && _isSameDay(date, selectedDay!);

    return Expanded(
      child: InkWell(
        onTap: () => onDayTap(date),
        child: Container(
          height: 56,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandBlue.withValues(alpha: 0.18) : null,
            borderRadius: BorderRadius.circular(8),
            border: isToday ? Border.all(color: AppColors.brandBlue, width: 1.4) : null,
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            children: [
              Text('$day', style: const TextStyle(fontSize: 13)),
              if (dayEvents.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 2,
                  children: [
                    for (var i = 0; i < dayEvents.length && i < 3; i++)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandBlue,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
