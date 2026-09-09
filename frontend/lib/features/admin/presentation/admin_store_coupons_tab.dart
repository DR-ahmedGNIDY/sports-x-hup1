import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/domain/entities/store_coupon.dart';
import '../application/admin_store_controllers.dart';
import 'admin_store_page.dart';

class AdminStoreCouponsTab extends ConsumerWidget {
  const AdminStoreCouponsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(adminCouponsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Discounts apply to the goods, never to the delivery fee.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => const _CouponEditor(coupon: null),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New code'),
              ),
            ],
          ),
        ),
        Expanded(
          child: AdminAsyncList<StoreCoupon>(
            value: coupons,
            emptyMessage: 'No discount codes yet.',
            onRetry: () => ref.invalidate(adminCouponsControllerProvider),
            builder: (context, items) => ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _CouponRow(coupon: items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _CouponRow extends StatelessWidget {
  const _CouponRow({required this.coupon});

  final StoreCoupon coupon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUsable = coupon.isUsableAt(DateTime.now());

    return ListTile(
      title: Row(
        children: [
          Text(
            coupon.code,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            coupon.type == CouponType.percent
                ? '${coupon.value}% off'
                : '${minorToPounds(coupon.value)} EGP off',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      subtitle: Text(_describe(coupon)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // One word for the state a customer would experience, rather than
          // making the merchant work it out from the dates and the counter.
          Text(
            isUsable ? 'Live' : _whyNotUsable(coupon),
            style: TextStyle(
              fontSize: 12,
              color: isUsable ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => _CouponEditor(coupon: coupon),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ],
      ),
    );
  }

  String _describe(StoreCoupon coupon) {
    final parts = <String>[
      if (coupon.minSubtotalMinor > 0)
        'min basket ${minorToPounds(coupon.minSubtotalMinor)} EGP',
      coupon.maxRedemptions == null
        ? '${coupon.redemptions} used'
        : '${coupon.redemptions} of ${coupon.maxRedemptions} used',
      if (coupon.startsAt != null) 'from ${_day(coupon.startsAt!)}',
      if (coupon.endsAt != null) 'until ${_day(coupon.endsAt!)}',
    ];
    return parts.join('  ·  ');
  }

  String _whyNotUsable(StoreCoupon coupon) {
    final now = DateTime.now();
    if (!coupon.isActive) return 'Off';
    if (coupon.isExhausted) return 'Used up';
    if (coupon.startsAt != null && coupon.startsAt!.isAfter(now)) {
      return 'Scheduled';
    }
    return 'Expired';
  }

  String _day(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _CouponEditor extends ConsumerStatefulWidget {
  const _CouponEditor({required this.coupon});

  final StoreCoupon? coupon;

  @override
  ConsumerState<_CouponEditor> createState() => _CouponEditorState();
}

class _CouponEditorState extends ConsumerState<_CouponEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.coupon?.code);
  late CouponType _type = widget.coupon?.type ?? CouponType.percent;
  late final _value = TextEditingController(
    text: widget.coupon == null
        ? ''
        : widget.coupon!.type == CouponType.percent
        ? '${widget.coupon!.value}'
        : minorToPounds(widget.coupon!.value),
  );
  late final _minSubtotal = TextEditingController(
    text: widget.coupon == null || widget.coupon!.minSubtotalMinor == 0
        ? ''
        : minorToPounds(widget.coupon!.minSubtotalMinor),
  );
  late final _maxRedemptions = TextEditingController(
    text: widget.coupon?.maxRedemptions?.toString() ?? '',
  );
  late DateTime? _startsAt = widget.coupon?.startsAt;
  late DateTime? _endsAt = widget.coupon?.endsAt;
  late bool _isActive = widget.coupon?.isActive ?? true;

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_code, _value, _minSubtotal, _maxRedemptions]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.coupon != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit code' : 'New code'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _code,
                  // The code is what customers already hold, so the server
                  // refuses to change it; the field is locked rather than
                  // letting the merchant discover that on save.
                  enabled: !isEditing,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Code',
                    helperText: isEditing
                        ? 'A code cannot be renamed once customers have it'
                        : 'Letters, digits and hyphens',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'Required';
                    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(text)) {
                      return 'Letters, digits and hyphens only';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CouponType>(
                        initialValue: _type,
                        decoration: const InputDecoration(labelText: 'Kind'),
                        items: const [
                          DropdownMenuItem(
                            value: CouponType.percent,
                            child: Text('Percentage off'),
                          ),
                          DropdownMenuItem(
                            value: CouponType.fixed,
                            child: Text('Fixed amount off'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _type = value ?? CouponType.percent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _value,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _type == CouponType.percent
                              ? 'Percent'
                              : 'Amount (EGP)',
                        ),
                        validator: _valueValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minSubtotal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum basket (EGP, optional)',
                    // Says which number it is measured against, because the
                    // distinction decides whether a basket qualifies in one
                    // governorate but not another.
                    helperText: 'Compared against the goods, before shipping',
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ||
                          poundsToMinor(value!) != null
                      ? null
                      : 'Enter an amount like 500.00',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxRedemptions,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Usage limit (optional)',
                    helperText: 'Leave empty for unlimited',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final parsed = int.tryParse(text);
                    return parsed == null || parsed < 1
                        ? 'A whole number, 1 or more'
                        : null;
                  },
                ),
                const SizedBox(height: 8),
                _DateField(
                  label: 'Starts (optional)',
                  value: _startsAt,
                  onChanged: (value) => setState(() => _startsAt = value),
                ),
                _DateField(
                  label: 'Ends (optional)',
                  value: _endsAt,
                  onChanged: (value) => setState(() => _endsAt = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Off stops it regardless of dates'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  /// A percentage and an amount are different numbers in the same field, so
  /// they are validated differently: 15 means 15% one way and 0.15 EGP the
  /// other, and only one of them has a ceiling.
  String? _valueValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Required';
    if (_type == CouponType.percent) {
      final percent = int.tryParse(text);
      if (percent == null || percent < 1 || percent > 100) {
        return 'A whole percent between 1 and 100';
      }
      return null;
    }
    final minor = poundsToMinor(text);
    return minor == null || minor < 1 ? 'Enter an amount like 50.00' : null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startsAt != null && _endsAt != null && !_endsAt!.isAfter(_startsAt!)) {
      setState(() => _error = 'The end date must be after the start.');
      return;
    }

    final minSubtotal = poundsToMinor(_minSubtotal.text);
    final body = <String, dynamic>{
      'code': _code.text.trim().toUpperCase(),
      'type': _type.wireValue,
      'value': _type == CouponType.percent
          ? int.parse(_value.text.trim())
          : poundsToMinor(_value.text),
      if (_minSubtotal.text.trim().isNotEmpty) 'minSubtotalMinor': minSubtotal,
      if (_maxRedemptions.text.trim().isNotEmpty)
        'maxRedemptions': int.parse(_maxRedemptions.text.trim()),
      if (_startsAt != null) 'startsAt': _startsAt!.toIso8601String(),
      if (_endsAt != null) 'endsAt': _endsAt!.toIso8601String(),
      'isActive': _isActive,
    };

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final controller = ref.read(adminCouponsControllerProvider.notifier);
      if (widget.coupon == null) {
        await controller.create(body);
      } else {
        await controller.save(widget.coupon!.id, body);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value == null
            ? 'Not set'
            : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-'
                  '${value!.day.toString().padLeft(2, '0')}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(
              tooltip: 'Clear',
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close, size: 16),
            ),
          IconButton(
            tooltip: 'Pick a date',
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) onChanged(picked);
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
          ),
        ],
      ),
    );
  }
}
