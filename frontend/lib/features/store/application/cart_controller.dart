import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/cart_item.dart';
import '../domain/entities/store_product.dart';

/// Where the cart is kept between visits.
///
/// SharedPreferences rather than the server: a guest has no session to hang
/// a server cart on, and the cart has to be re-priced at checkout regardless
/// because prices and stock move. That makes a server cart a second source
/// of truth with no authority — this one is a convenience, and losing it
/// costs the customer a re-add, not an order.
const _cartStorageKey = 'sxh_store_cart_v1';

/// Guards against a single line asking for an implausible quantity. The real
/// limit is the variant's stock, which only the server can enforce.
const int maxLineQuantity = 50;

final cartControllerProvider =
    NotifierProvider<CartController, List<CartItem>>(CartController.new);

/// Set in `main_store.dart`, the same way the app's other storage
/// dependencies are injected at the root.
final cartPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('cartPreferencesProvider was not overridden'),
);

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => _restore();

  SharedPreferences get _prefs => ref.read(cartPreferencesProvider);

  List<CartItem> _restore() {
    final raw = _prefs.getString(_cartStorageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error) {
      // A cart written by an older build, or corrupted storage. Starting
      // empty is the right failure: it costs a re-add, whereas throwing
      // here would take down the storefront on launch.
      debugPrint('Cart: discarding unreadable stored cart ($error)');
      return const [];
    }
  }

  Future<void> _persist(List<CartItem> items) async {
    state = items;
    await _prefs.setString(
      _cartStorageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  /// Adding a variant already in the cart increases its quantity rather than
  /// appending a second line — the same product in two sizes is two lines,
  /// but the same variant twice is one.
  Future<void> add(
    StoreProduct product,
    ProductVariant variant, {
    int quantity = 1,
  }) async {
    final existing = state.where((item) => item.key == variant.id).firstOrNull;

    final items = [
      for (final item in state)
        if (item.key == variant.id)
          item.copyWith(
            quantity: _clampQuantity(item.quantity + quantity),
          )
        else
          item,
    ];

    if (existing == null) {
      items.add(
        CartItem(
          productId: product.id,
          variantId: variant.id,
          title: product.title,
          unitPriceMinor: product.priceMinor,
          quantity: _clampQuantity(quantity),
          variantLabel: variant.label(),
          imageUrl: product.imageUrl,
          slug: product.slug,
        ),
      );
    }

    await _persist(items);
  }

  Future<void> setQuantity(String variantId, int quantity) async {
    if (quantity < 1) return remove(variantId);
    await _persist([
      for (final item in state)
        if (item.key == variantId)
          item.copyWith(quantity: _clampQuantity(quantity))
        else
          item,
    ]);
  }

  Future<void> remove(String variantId) async =>
      _persist([for (final item in state) if (item.key != variantId) item]);

  /// Called after a successful checkout — the cart's contents are now an
  /// order, and leaving them behind invites a duplicate purchase.
  Future<void> clear() async => _persist(const []);

  int _clampQuantity(int quantity) =>
      quantity.clamp(1, maxLineQuantity).toInt();
}

/// The badge on the header's cart icon: total units, not distinct lines,
/// because that is what a shopper counts.
final cartCountProvider = Provider<int>((ref) {
  return ref
      .watch(cartControllerProvider)
      .fold(0, (sum, item) => sum + item.quantity);
});

/// Indicative only — the server totals the order independently at checkout,
/// and its answer is the one the customer pays.
final cartSubtotalMinorProvider = Provider<int>((ref) {
  return ref
      .watch(cartControllerProvider)
      .fold(0, (sum, item) => sum + item.lineTotalMinor);
});
