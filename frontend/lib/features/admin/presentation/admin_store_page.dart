import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_state.dart';
import 'admin_store_categories_tab.dart';
import 'admin_store_orders_tab.dart';
import 'admin_store_products_tab.dart';
import 'admin_store_shipping_tab.dart';

/// Store administration, as a fifth area of the existing admin dashboard
/// rather than a separate tool — same app, same session, same admin guard.
///
/// Desktop only, like the other admin pages: the roadmap does not call for a
/// mobile layout here, and a merchant editing a product table on a phone is
/// not a case worth designing for before anyone asks.
class AdminStorePage extends ConsumerStatefulWidget {
  const AdminStorePage({super.key});

  @override
  ConsumerState<AdminStorePage> createState() => _AdminStorePageState();
}

class _AdminStorePageState extends ConsumerState<AdminStorePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Store', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Products'),
              Tab(text: 'Categories'),
              Tab(text: 'Orders'),
              Tab(text: 'Shipping'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                AdminStoreProductsTab(),
                AdminStoreCategoriesTab(),
                AdminStoreOrdersTab(),
                AdminStoreShippingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared by the four tabs: the loading/error/empty shell around a list, so
/// each tab only has to describe its own rows.
class AdminAsyncList<T> extends StatelessWidget {
  const AdminAsyncList({
    super.key,
    required this.value,
    required this.emptyMessage,
    required this.builder,
    required this.onRetry,
  });

  final AsyncValue<List<T>> value;
  final String emptyMessage;
  final Widget Function(BuildContext context, List<T> items) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (items) => items.isEmpty
          ? Center(child: Text(emptyMessage))
          : builder(context, items),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorState(message: '$error', onRetry: onRetry),
    );
  }
}

/// Piastres in, a field the merchant types pounds into, and back again.
///
/// The API speaks integer minor units end to end, but a merchant thinks in
/// pounds — so the conversion is confined to this pair rather than being
/// scattered through the forms.
String minorToPounds(int minor) => (minor / 100).toStringAsFixed(2);

int? poundsToMinor(String input) {
  final parsed = double.tryParse(input.trim());
  if (parsed == null || parsed < 0) return null;
  // Rounded, not truncated: 74.99 parses to 74.98999... in binary, and
  // truncating would quietly charge a piastre less. The epsilon nudges the
  // other side of that same imprecision — 1.005 parses to 1.00499999...,
  // which lands just *under* the .5 boundary and would round down instead
  // of up without it.
  return (parsed * 100 + 1e-9).round();
}
