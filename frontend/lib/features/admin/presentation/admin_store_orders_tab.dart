import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/domain/entities/store_order.dart';
import '../application/admin_store_controllers.dart';
import 'admin_store_page.dart';

/// Which moves the API will accept from each state. Mirrors
/// `ALLOWED_STATUS_TRANSITIONS` on the backend so the merchant is offered
/// only the buttons that will work — the server remains the authority, this
/// just avoids presenting a dead end.
const Map<OrderStatus, List<OrderStatus>> _allowedTransitions = {
  OrderStatus.pending: [OrderStatus.confirmed, OrderStatus.cancelled],
  OrderStatus.confirmed: [OrderStatus.shipped, OrderStatus.cancelled],
  OrderStatus.shipped: [OrderStatus.delivered],
  OrderStatus.delivered: [],
  OrderStatus.cancelled: [],
};

String _statusLabel(OrderStatus status) => switch (status) {
  OrderStatus.pending => 'Pending',
  OrderStatus.confirmed => 'Confirmed',
  OrderStatus.shipped => 'Shipped',
  OrderStatus.delivered => 'Delivered',
  OrderStatus.cancelled => 'Cancelled',
};

class AdminStoreOrdersTab extends ConsumerWidget {
  const AdminStoreOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersControllerProvider);
    final controller = ref.read(adminOrdersControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            spacing: 8,
            children: [
              // "All" first and selected by default — a queue that hides
              // orders behind a filter is how one gets missed.
              ChoiceChip(
                label: const Text('All'),
                selected: controller.filter == null,
                onSelected: (_) => controller.setFilter(null),
              ),
              for (final status in OrderStatus.values)
                ChoiceChip(
                  label: Text(_statusLabel(status)),
                  selected: controller.filter == status,
                  onSelected: (_) => controller.setFilter(status),
                ),
            ],
          ),
        ),
        Expanded(
          child: AdminAsyncList<StoreOrder>(
            value: orders,
            emptyMessage: 'No orders here.',
            onRetry: () => ref.invalidate(adminOrdersControllerProvider),
            builder: (context, items) => ListView.separated(
              itemCount: items.length + (controller.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: controller.loadMore,
                        child: const Text('Load more'),
                      ),
                    ),
                  );
                }
                return _OrderRow(order: items[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderRow extends ConsumerWidget {
  const _OrderRow({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moves = _allowedTransitions[order.status] ?? const <OrderStatus>[];
    final units = order.lines.fold<int>(0, (sum, l) => sum + l.quantity);

    return ExpansionTile(
      title: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              order.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(order.address.fullName)),
          SizedBox(width: 160, child: Text(order.address.governorateName.en)),
          SizedBox(
            width: 110,
            child: Text('${minorToPounds(order.totalMinor)} EGP'),
          ),
          SizedBox(width: 110, child: Text(_statusLabel(order.status))),
        ],
      ),
      subtitle: Text(
        '$units item${units == 1 ? '' : 's'}  ·  ${order.email}'
        // Whether the buyer had an account changes how the merchant can
        // reach them about the order, so it is on the row, not buried.
        '${order.isGuestOrder ? '  ·  Guest' : ''}',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in order.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${line.quantity} × ${line.title.en}'
                    '${line.size == null ? '' : ' · ${line.size}'}'
                    '${line.colour == null ? '' : ' · ${line.colour}'}'
                    '   —   ${minorToPounds(line.lineTotalMinor)} EGP',
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '${order.address.street}, ${order.address.city}, '
                '${order.address.governorateName.en}  ·  ${order.address.phone}',
              ),
              if (order.address.notes != null &&
                  order.address.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Notes: ${order.address.notes}'),
              ],
              const SizedBox(height: 8),
              Text(
                'Subtotal ${minorToPounds(order.subtotalMinor)}  ·  '
                'Shipping ${minorToPounds(order.shippingFeeMinor)}  ·  '
                'Total ${minorToPounds(order.totalMinor)} EGP',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (moves.isEmpty)
                const Text('This order is closed.')
              else
                Wrap(
                  spacing: 8,
                  children: [
                    for (final next in moves)
                      FilledButton.tonal(
                        onPressed: () => _move(context, ref, next),
                        child: Text('Mark ${_statusLabel(next).toLowerCase()}'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    OrderStatus next,
  ) async {
    // Cancelling returns stock to the variants, which is not something to
    // do on a stray click; advancing an order is reversible enough not to
    // need a dialog.
    if (next == OrderStatus.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cancel ${order.orderNumber}?'),
          content: const Text(
            'The items go back into stock and the order cannot be reopened.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep it'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancel order'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await ref
        .read(adminOrdersControllerProvider.notifier)
        .setStatus(order.id, next);
  }
}
