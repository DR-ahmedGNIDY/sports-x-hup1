import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/calendar_events_controller.dart';
import '../../domain/entities/calendar_event.dart';
import 'event_card.dart';

/// The event-creation form — type, custom name (OTHER only), team/birth-year
/// or "all players", location, recurrence, start/end time, and opponent
/// (MATCH only). Shown as a modal sheet from the tapped day.
Future<void> showCreateEventSheet(
  BuildContext context, {
  required WidgetRef ref,
  required DateTime day,
  required List<int> availableBirthYears,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // The calendar lives inside a shell branch; without the root navigator
    // the sheet is laid out under the mobile tab bar, which hides its submit
    // button.
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) => _CreateEventSheet(
      ref: ref,
      day: day,
      availableBirthYears: availableBirthYears,
    ),
  );
}

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet({
    required this.ref,
    required this.day,
    required this.availableBirthYears,
  });

  final WidgetRef ref;
  final DateTime day;
  final List<int> availableBirthYears;

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  CalendarEventType _type = CalendarEventType.training;
  CalendarEventRecurrence _recurrence = CalendarEventRecurrence.none;
  final _customNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _opponentController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 0);
  int? _rosterBirthYear; // null = all players
  bool _submitting = false;

  @override
  void dispose() {
    _customNameController.dispose();
    _locationController.dispose();
    _opponentController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await widget.ref
          .read(calendarEventActionsProvider)
          .create(
            type: _type,
            customTypeName: _type == CalendarEventType.other
                ? _customNameController.text.trim()
                : null,
            date: widget.day,
            startTime: _formatTime(_startTime),
            endTime: _formatTime(_endTime),
            location: _locationController.text.trim(),
            recurrence: _recurrence,
            opponentName: _type == CalendarEventType.match
                ? _opponentController.text.trim()
                : null,
            rosterBirthYear: _rosterBirthYear,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('حدث جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SegmentedButton<CalendarEventType>(
                segments: [
                  for (final type in CalendarEventType.values)
                    ButtonSegment(value: type, label: Text(calendarEventTypeLabel(type))),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              if (_type == CalendarEventType.other) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customNameController,
                  decoration: const InputDecoration(labelText: 'اسم النشاط'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
              ],
              if (_type == CalendarEventType.match) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _opponentController,
                  decoration: const InputDecoration(labelText: 'اسم الفريق المنافس'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'الموقع'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _rosterBirthYear,
                decoration: const InputDecoration(labelText: 'الفئة العمرية'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('كل اللاعبين')),
                  for (final year in widget.availableBirthYears)
                    DropdownMenuItem<int?>(value: year, child: Text('مواليد $year')),
                ],
                onChanged: (value) => setState(() => _rosterBirthYear = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text('بداية: ${_formatTime(_startTime)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text('نهاية: ${_formatTime(_endTime)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CalendarEventRecurrence>(
                initialValue: _recurrence,
                decoration: const InputDecoration(labelText: 'التكرار'),
                items: const [
                  DropdownMenuItem(value: CalendarEventRecurrence.none, child: Text('مرة واحدة')),
                  DropdownMenuItem(value: CalendarEventRecurrence.weekly, child: Text('أسبوعي')),
                  DropdownMenuItem(value: CalendarEventRecurrence.monthly, child: Text('شهري')),
                ],
                onChanged: (value) => setState(() => _recurrence = value ?? CalendarEventRecurrence.none),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إنشاء الحدث'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
