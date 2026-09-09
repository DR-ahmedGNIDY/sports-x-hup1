import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/error_state.dart';
import '../../store/domain/entities/store_overview.dart';
import '../application/admin_store_controllers.dart';
import 'admin_store_page.dart';

/// The first thing the merchant sees: what happened today, and what needs
/// doing now. Six numbers, no charts — a store this size has nothing a
/// trend line would reveal that the counts do not.
class AdminStoreOverviewTab extends ConsumerWidget {
  const AdminStoreOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(adminStoreOverviewProvider);

    return overview.when(
      data: (data) => _Cards(overview: data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: '$error',
        onRetry: () => ref.invalidate(adminStoreOverviewProvider),
      ),
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards({required this.overview});

  final StoreOverview overview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              label: 'Orders today',
              value: '${overview.ordersToday}',
              icon: Icons.receipt_long_outlined,
            ),
            _StatCard(
              label: 'Takings today',
              value: '${minorToPounds(overview.revenueTodayMinor)} EGP',
              icon: Icons.payments_outlined,
              // Cancelled orders are excluded server-side; saying so here
              // stops the number reading as a discrepancy against the
              // orders tab, where cancellations are still listed.
              hint: 'Cancelled orders excluded',
            ),
            _StatCard(
              label: 'Awaiting you',
              value: '${overview.pendingOrders}',
              icon: Icons.pending_actions_outlined,
              // The only card that is a to-do rather than a fact, so it is
              // the only one that changes colour.
              isAlert: overview.pendingOrders > 0,
            ),
            _StatCard(
              label: 'Out of stock',
              value: '${overview.outOfStockProducts}',
              icon: Icons.remove_shopping_cart_outlined,
              hint: 'Listed, but nothing buyable',
              isAlert: overview.outOfStockProducts > 0,
            ),
            _StatCard(
              label: 'Running low',
              value: '${overview.lowStockProducts}',
              icon: Icons.inventory_2_outlined,
              hint: 'A size with 3 or fewer left',
            ),
            _StatCard(
              label: 'Listed products',
              value: '${overview.activeProducts}',
              icon: Icons.sell_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.hint,
    this.isAlert = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? hint;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isAlert ? scheme.error : scheme.onSurfaceVariant;

    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isAlert ? scheme.error : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
