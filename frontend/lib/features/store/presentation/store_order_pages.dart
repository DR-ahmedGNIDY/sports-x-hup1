import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/checkout_controller.dart';
import '../domain/entities/store_order.dart';
import 'widgets/money.dart';
import 'widgets/store_scaffold.dart';
import 'store_paths.dart';

String orderStatusLabel(AppLocalizations l10n, OrderStatus status) =>
    switch (status) {
      OrderStatus.pending => l10n.storeStatusPending,
      OrderStatus.confirmed => l10n.storeStatusConfirmed,
      OrderStatus.shipped => l10n.storeStatusShipped,
      OrderStatus.delivered => l10n.storeStatusDelivered,
      OrderStatus.cancelled => l10n.storeStatusCancelled,
    };

/// Shown straight after checkout.
///
/// The order lives in the checkout controller rather than being refetched:
/// a guest has no session, so re-reading it here would need the tracking
/// credentials the customer has not been shown yet.
class StoreOrderConfirmationPage extends ConsumerWidget {
  const StoreOrderConfirmationPage({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final order = ref.watch(checkoutControllerProvider).order;

    return StoreScaffold(
      showBottomBar: false,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.check_circle_outline, size: 56),
          const SizedBox(height: 16),
          Text(
            l10n.storeOrderPlaced,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.storeOrderNumberIs,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          SelectableText(
            orderNumber,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          // Only a guest has to keep the number — a signed-in customer can
          // find the order in their history.
          if (order == null || order.isGuestOrder)
            Text(
              l10n.storeGuestKeepNumber,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 32),
          if (order != null) _OrderSummary(order: order),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => context.go(StorePaths.home),
            child: Text(l10n.storeBackToStore),
          ),
        ],
      ),
    );
  }
}

/// The guest lookup form, and the order it finds.
class StoreTrackOrderPage extends ConsumerStatefulWidget {
  const StoreTrackOrderPage({super.key});

  @override
  ConsumerState<StoreTrackOrderPage> createState() =>
      _StoreTrackOrderPageState();
}

class _StoreTrackOrderPageState extends ConsumerState<StoreTrackOrderPage> {
  final _number = TextEditingController();
  final _email = TextEditingController();
  ({String orderNumber, String email})? _lookup;

  @override
  void dispose() {
    _number.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lookup = _lookup;

    return StoreScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.storeTrackOrder,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _number,
            decoration: InputDecoration(
              labelText: l10n.storeTrackOrderNumberLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            // Both halves are required: order numbers are sequential, so the
            // number alone would let anyone walk the order book.
            decoration: InputDecoration(labelText: l10n.storeEmailLabel),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => setState(() {
              _lookup = (
                orderNumber: _number.text.trim(),
                email: _email.text.trim(),
              );
            }),
            child: Text(l10n.storeTrackSubmit),
          ),
          const SizedBox(height: 32),
          if (lookup != null)
            ref
                .watch(trackedOrderProvider(lookup))
                .when(
                  data: (order) => _OrderSummary(order: order),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  // A wrong email and a wrong number are the same answer by
                  // design — the server will not confirm which was right.
                  error: (_, _) => Text(l10n.storeOrderNotFound),
                ),
        ],
      ),
    );
  }
}

/// The signed-in customer's own orders.
class StoreMyOrdersPage extends ConsumerWidget {
  const StoreMyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final orders = ref.watch(myOrdersProvider);

    return StoreScaffold(
      child: orders.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.storeNoOrders),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.go(StorePaths.track),
                    child: Text(l10n.storeTrackOrder),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 20),
            itemBuilder: (context, index) =>
                _OrderSummary(order: items[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        // Reaching this while signed out is the common case, not a bug —
        // the tracking form is the guest's route to the same information.
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.storeNoOrders),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go(StorePaths.track),
                child: Text(l10n.storeTrackOrder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                orderStatusLabel(l10n, order.status),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const Divider(height: 20),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${line.quantity} × ${line.title.resolve(isArabic)}'
                      '${line.size == null ? '' : ' (${line.size})'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    formatMoney(line.lineTotalMinor, isArabic: isArabic),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          const Divider(height: 20),
          _SummaryRow(
            label: l10n.storeSubtotal,
            value: formatMoney(order.subtotalMinor, isArabic: isArabic),
          ),
          _SummaryRow(
            label:
                '${l10n.storeShippingFee} — '
                '${order.address.governorateName.resolve(isArabic)}',
            value: formatMoney(order.shippingFeeMinor, isArabic: isArabic),
          ),
          _SummaryRow(
            label: l10n.storeTotal,
            value: formatMoney(order.totalMinor, isArabic: isArabic),
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? const TextStyle(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
