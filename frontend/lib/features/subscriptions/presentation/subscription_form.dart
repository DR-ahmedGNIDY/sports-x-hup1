import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/subscriptions_controllers.dart';
import '../data/subscriptions_repository.dart';
import '../domain/subscription.dart';
import 'subscription_widgets.dart';

/// Opens the add / edit form as a bottom sheet. [existing] null adds a new
/// subscription for [playerUserId].
Future<void> showSubscriptionForm(
  BuildContext context, {
  required String playerUserId,
  PlayerSubscription? existing,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      _SubscriptionForm(playerUserId: playerUserId, existing: existing),
);

/// Pounds as typed ("1500" or "1500.5") to piastres.
int? _minorFrom(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value == null ? null : (value * 100).round();
}

String _majorFrom(int minor) =>
    minor % 100 == 0 ? '${minor ~/ 100}' : (minor / 100).toStringAsFixed(2);

DateTime _parse(String iso) => DateTime.parse(iso);

class _SubscriptionForm extends ConsumerStatefulWidget {
  const _SubscriptionForm({required this.playerUserId, this.existing});

  final String playerUserId;
  final PlayerSubscription? existing;

  @override
  ConsumerState<_SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends ConsumerState<_SubscriptionForm> {
  final _formKey = GlobalKey<FormState>();
  late SubscriptionPlan _plan;
  late DateTime _start;
  late DateTime _end;
  late final TextEditingController _amount;
  late final TextEditingController _paid;
  late final TextEditingController _notes;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now();
    _plan = existing?.plan ?? SubscriptionPlan.monthly;
    _start = existing == null
        ? DateTime(now.year, now.month, now.day)
        : _parse(existing.startDate);
    _end = existing == null ? _endFor(_plan, _start) : _parse(existing.endDate);
    _amount = TextEditingController(
      text: existing == null ? '' : _majorFrom(existing.amountMinor),
    );
    _paid = TextEditingController(
      text: existing == null ? '' : _majorFrom(existing.paidMinor),
    );
    _notes = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _paid.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// A month (or three) from the start, ending the day before the same
  /// date — 1 Nov to 30 Nov, not to 1 Dec.
  DateTime _endFor(SubscriptionPlan plan, DateTime start) => switch (plan) {
    SubscriptionPlan.monthly => DateTime(start.year, start.month + 1, start.day - 1),
    SubscriptionPlan.quarterly => DateTime(start.year, start.month + 3, start.day - 1),
    SubscriptionPlan.custom => _end,
  };

  Future<void> _pick({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_plan != SubscriptionPlan.custom) _end = _endFor(_plan, _start);
      } else {
        _end = picked;
        _plan = SubscriptionPlan.custom;
      }
    });
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    if (_end.isBefore(_start)) {
      setState(() => _error = l10n.subscriptionInvalidDates);
      return;
    }
    final amount = _minorFrom(_amount.text) ?? 0;
    final paid = _minorFrom(_paid.text) ?? 0;
    if (paid > amount) {
      setState(() => _error = l10n.subscriptionInvalidPaid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'plan': _plan.wireValue,
      'startDate': isoDateOf(_start),
      'endDate': isoDateOf(_end),
      'amountMinor': amount,
      'paidMinor': paid,
      'notes': _notes.text.trim(),
    };
    try {
      final repository = ref.read(subscriptionsRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repository.create({...body, 'playerUserId': widget.playerUserId});
      } else {
        await repository.update(existing.id, body);
      }
      refreshPlayerSubscriptions(ref, widget.playerUserId);
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final money = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null
                    ? l10n.subscriptionAdd
                    : l10n.subscriptionEdit,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(l10n.subscriptionPlanLabel, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<SubscriptionPlan>(
                segments: [
                  for (final plan in SubscriptionPlan.values)
                    ButtonSegment(
                      value: plan,
                      label: Text(subscriptionPlanLabel(l10n, plan)),
                    ),
                ],
                selected: {_plan},
                onSelectionChanged: (selection) => setState(() {
                  _plan = selection.first;
                  if (_plan != SubscriptionPlan.custom) {
                    _end = _endFor(_plan, _start);
                  }
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: l10n.subscriptionStartDate,
                      value: isoDateOf(_start),
                      onTap: () => _pick(start: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: l10n.subscriptionEndDate,
                      value: isoDateOf(_end),
                      onTap: () => _pick(start: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: money,
                      decoration: InputDecoration(
                        labelText: l10n.subscriptionAmount,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _paid,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: money,
                      decoration: InputDecoration(
                        labelText: l10n.subscriptionPaidAmount,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.subscriptionNotes),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : () => _save(l10n),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      child: Text(displayDate(value)),
    ),
  );
}
