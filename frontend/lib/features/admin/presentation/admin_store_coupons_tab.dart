import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../store/domain/entities/store_coupon.dart';
import '../../store/presentation/widgets/money.dart';
import '../application/admin_store_controllers.dart';
import 'admin_store_page.dart';

class AdminStoreCouponsTab extends ConsumerWidget {
  const AdminStoreCouponsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final coupons = ref.watch(adminCouponsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adminCouponsIntro,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => const _CouponEditor(coupon: null),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.adminCouponNewCode),
              ),
            ],
          ),
        ),
        Expanded(
          child: AdminAsyncList<StoreCoupon>(
            value: coupons,
            emptyMessage: l10n.adminCouponsEmpty,
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
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
                ? l10n.adminCouponPercentOff(coupon.value)
                : l10n.adminCouponAmountOff(formatMoney(coupon.value, isArabic: isArabic)),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      subtitle: Text(_describe(l10n, coupon, isArabic)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // One word for the state a customer would experience, rather than
          // making the merchant work it out from the dates and the counter.
          Text(
            isUsable ? l10n.adminCouponLive : _whyNotUsable(l10n, coupon),
            style: TextStyle(
              fontSize: 12,
              color: isUsable ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: l10n.editLabel,
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

  String _describe(AppLocalizations l10n, StoreCoupon coupon, bool isArabic) {
    final parts = <String>[
      if (coupon.minSubtotalMinor > 0)
        l10n.adminCouponMinBasket(formatMoney(coupon.minSubtotalMinor, isArabic: isArabic)),
      coupon.maxRedemptions == null
        ? l10n.adminCouponUsedCount(coupon.redemptions)
        : l10n.adminCouponUsedOfMax(coupon.redemptions, coupon.maxRedemptions!),
      if (coupon.startsAt != null) l10n.adminCouponFrom(_day(coupon.startsAt!)),
      if (coupon.endsAt != null) l10n.adminCouponUntil(_day(coupon.endsAt!)),
    ];
    return parts.join('  ·  ');
  }

  String _whyNotUsable(AppLocalizations l10n, StoreCoupon coupon) {
    final now = DateTime.now();
    if (!coupon.isActive) return l10n.adminCouponOff;
    if (coupon.isExhausted) return l10n.adminCouponUsedUp;
    if (coupon.startsAt != null && coupon.startsAt!.isAfter(now)) {
      return l10n.adminCouponScheduled;
    }
    return l10n.adminCouponExpired;
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
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.coupon != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.adminCouponEditCode : l10n.adminCouponNewCode),
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
                    labelText: l10n.adminCouponCodeLabel,
                    helperText: isEditing
                        ? l10n.adminCouponCodeLockedHelper
                        : l10n.adminCouponCodeHelper,
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return l10n.storeRequiredField;
                    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(text)) {
                      return l10n.adminCouponCodeInvalid;
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
                        decoration: InputDecoration(labelText: l10n.adminCouponKindLabel),
                        items: [
                          DropdownMenuItem(
                            value: CouponType.percent,
                            child: Text(l10n.adminCouponPercentageOff),
                          ),
                          DropdownMenuItem(
                            value: CouponType.fixed,
                            child: Text(l10n.adminCouponFixedAmountOff),
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
                              ? l10n.adminCouponPercentLabel
                              : l10n.adminCouponAmountEgpLabel,
                        ),
                        validator: (value) => _valueValidator(l10n, value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minSubtotal,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.adminCouponMinBasketLabel,
                    // Says which number it is measured against, because the
                    // distinction decides whether a basket qualifies in one
                    // governorate but not another.
                    helperText: l10n.adminCouponMinBasketHelper,
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ||
                          poundsToMinor(value!) != null
                      ? null
                      : l10n.adminCouponAmountExample,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxRedemptions,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.adminCouponUsageLimitLabel,
                    helperText: l10n.adminCouponUsageLimitHelper,
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final parsed = int.tryParse(text);
                    return parsed == null || parsed < 1
                        ? l10n.adminCouponUsageLimitError
                        : null;
                  },
                ),
                const SizedBox(height: 8),
                _DateField(
                  label: l10n.adminCouponStartsLabel,
                  value: _startsAt,
                  onChanged: (value) => setState(() => _startsAt = value),
                ),
                _DateField(
                  label: l10n.adminCouponEndsLabel,
                  value: _endsAt,
                  onChanged: (value) => setState(() => _endsAt = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.adminActiveLabel),
                  subtitle: Text(l10n.adminCouponActiveHint),
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
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: _busy ? null : () => _save(l10n),
          child: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.saveLabel),
        ),
      ],
    );
  }

  /// A percentage and an amount are different numbers in the same field, so
  /// they are validated differently: 15 means 15% one way and 0.15 EGP the
  /// other, and only one of them has a ceiling.
  String? _valueValidator(AppLocalizations l10n, String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return l10n.storeRequiredField;
    if (_type == CouponType.percent) {
      final percent = int.tryParse(text);
      if (percent == null || percent < 1 || percent > 100) {
        return l10n.adminCouponPercentRangeError;
      }
      return null;
    }
    final minor = poundsToMinor(text);
    return minor == null || minor < 1 ? l10n.adminCouponAmountMinError : null;
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startsAt != null && _endsAt != null && !_endsAt!.isAfter(_startsAt!)) {
      setState(() => _error = l10n.adminCouponEndAfterStartError);
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
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value == null
            ? l10n.adminCouponNotSet
            : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-'
                  '${value!.day.toString().padLeft(2, '0')}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(
              tooltip: l10n.adminBannerClear,
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close, size: 16),
            ),
          IconButton(
            tooltip: l10n.adminCouponPickDate,
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
