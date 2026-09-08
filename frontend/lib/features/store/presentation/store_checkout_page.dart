import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/cart_controller.dart';
import '../application/catalog_providers.dart';
import '../application/checkout_controller.dart';
import '../domain/entities/shipping_zone.dart';
import 'widgets/money.dart';
import 'widgets/store_scaffold.dart';
import 'store_paths.dart';

/// Matches the backend's own check (`create-order.dto.ts`). Duplicated
/// rather than shared because the two serve different purposes: this one
/// tells the customer before they submit, the server's one is the guarantee.
final _egyptianMobilePattern = RegExp(r'^(\+20|0)?1[0125][0-9]{8}$');
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class StoreCheckoutPage extends ConsumerStatefulWidget {
  const StoreCheckoutPage({super.key});

  @override
  ConsumerState<StoreCheckoutPage> createState() => _StoreCheckoutPageState();
}

class _StoreCheckoutPageState extends ConsumerState<StoreCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _street = TextEditingController();
  final _notes = TextEditingController();
  ShippingZone? _zone;

  @override
  void dispose() {
    for (final controller in [_name, _phone, _email, _city, _street, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final zones = ref.watch(shippingZonesProvider);
    final subtotal = ref.watch(cartSubtotalMinorProvider);
    final checkout = ref.watch(checkoutControllerProvider);

    final fee = _zone?.feeMinor;

    return StoreScaffold(
      showBottomBar: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.storeCheckoutTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _Field(
                  controller: _name,
                  label: l10n.storeFullNameLabel,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.storeRequiredField
                      : null,
                ),
                _Field(
                  controller: _phone,
                  label: l10n.storePhoneLabel,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      _egyptianMobilePattern.hasMatch((value ?? '').trim())
                      ? null
                      : l10n.storeInvalidPhone,
                ),
                _Field(
                  controller: _email,
                  label: l10n.storeEmailLabel,
                  keyboardType: TextInputType.emailAddress,
                  // Required even for a guest: it is the only handle they
                  // will have on the order afterwards.
                  validator: (value) => _emailPattern.hasMatch((value ?? '').trim())
                      ? null
                      : l10n.storeInvalidEmail,
                ),
                zones.when(
                  data: (items) => DropdownButtonFormField<ShippingZone>(
                    initialValue: _zone,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.storeGovernorateLabel,
                    ),
                    items: [
                      for (final zone in items)
                        DropdownMenuItem(
                          value: zone,
                          child: Text(
                            '${zone.name.resolve(isArabic)} — '
                            '${formatMoney(zone.feeMinor, isArabic: isArabic)}',
                          ),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? l10n.storeRequiredField : null,
                    onChanged: (value) => setState(() => _zone = value),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, _) => Text(l10n.genericErrorMessage),
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _city,
                  label: l10n.storeCityLabel,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.storeRequiredField
                      : null,
                ),
                _Field(
                  controller: _street,
                  label: l10n.storeStreetLabel,
                  maxLines: 2,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.storeRequiredField
                      : null,
                ),
                _Field(
                  controller: _notes,
                  label: l10n.storeNotesLabel,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Summary(subtotal: subtotal, feeMinor: fee),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 18),
              const SizedBox(width: 8),
              Text(l10n.storePaymentCod),
            ],
          ),
          const SizedBox(height: 20),
          if (checkout.error != null) ...[
            Text(
              checkout.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: checkout.isSubmitting ? null : _submit,
            child: checkout.isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.storePlaceOrder),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final zone = _zone;
    if (zone == null) return;

    final order = await ref
        .read(checkoutControllerProvider.notifier)
        .submit(
          email: _email.text.trim(),
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
          governorateCode: zone.code,
          city: _city.text.trim(),
          street: _street.text.trim(),
          notes: _notes.text.trim(),
        );

    if (!mounted || order == null) return;
    context.go(StorePaths.order(order.orderNumber));
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.subtotal, required this.feeMinor});

  final int subtotal;
  final int? feeMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final fee = feeMinor;

    return Column(
      children: [
        _Row(
          label: l10n.storeSubtotal,
          value: formatMoney(subtotal, isArabic: isArabic),
        ),
        _Row(
          label: l10n.storeShippingFee,
          // Dashes until a governorate is chosen — the fee genuinely is not
          // known before then, and showing zero would read as free.
          value: fee == null ? '—' : formatMoney(fee, isArabic: isArabic),
        ),
        const Divider(height: 20),
        _Row(
          label: l10n.storeTotal,
          value: formatMoney(subtotal + (fee ?? 0), isArabic: isArabic),
          isBold: true,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.isBold = false});

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
