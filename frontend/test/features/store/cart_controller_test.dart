import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_x_hub/features/store/application/cart_controller.dart';
import 'package:sport_x_hub/features/store/domain/entities/localized_text.dart';
import 'package:sport_x_hub/features/store/domain/entities/store_product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const product = StoreProduct(
    id: 'p1',
    title: LocalizedText(en: 'Black Cargo Shorts', ar: 'شورت كارجو أسود'),
    slug: 'black-cargo-shorts',
    priceMinor: 74000,
    inStock: true,
    imageUrl: 'https://img/1.jpg',
  );
  const large = ProductVariant(id: 'v-large', inStock: true, size: 'L');
  const medium = ProductVariant(id: 'v-medium', inStock: true, size: 'M');

  Future<ProviderContainer> buildContainer({
    Map<String, Object> initialStore = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialStore);
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [cartPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  group('CartController', () {
    test('adding the same variant twice merges into one line', () async {
      final container = await buildContainer();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);

      await cart.add(product, large);
      await cart.add(product, large);

      final items = container.read(cartControllerProvider);
      expect(items, hasLength(1));
      expect(items.single.quantity, 2);
    });

    test('the same product in two sizes is two lines', () async {
      final container = await buildContainer();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);

      await cart.add(product, large);
      await cart.add(product, medium);

      // The variant is the identity, not the product — the backend reserves
      // stock per variant, so the cart has to be shaped the same way.
      expect(container.read(cartControllerProvider), hasLength(2));
    });

    test('counts units rather than lines', () async {
      final container = await buildContainer();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);

      await cart.add(product, large, quantity: 3);
      await cart.add(product, medium, quantity: 2);

      expect(container.read(cartCountProvider), 5);
    });

    test('subtotals every line', () async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      await container
          .read(cartControllerProvider.notifier)
          .add(product, large, quantity: 3);

      expect(container.read(cartSubtotalMinorProvider), 222000);
    });

    test('setting a quantity below one removes the line', () async {
      final container = await buildContainer();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);
      await cart.add(product, large);

      await cart.setQuantity(large.id, 0);

      expect(container.read(cartControllerProvider), isEmpty);
    });

    test('clamps a line to the maximum quantity', () async {
      final container = await buildContainer();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);

      await cart.add(product, large, quantity: maxLineQuantity + 40);

      expect(container.read(cartControllerProvider).single.quantity,
          maxLineQuantity);
    });

    test('survives a restart', () async {
      final first = await buildContainer();
      await first.read(cartControllerProvider.notifier).add(product, large);
      final stored = first.read(cartPreferencesProvider).getString(
        'sxh_store_cart_v1',
      );
      first.dispose();

      // A second container over the same stored value stands in for the
      // customer coming back tomorrow.
      final second = await buildContainer(
        initialStore: {'sxh_store_cart_v1': stored!},
      );
      addTearDown(second.dispose);

      final items = second.read(cartControllerProvider);
      expect(items.single.variantId, large.id);
      expect(items.single.title.ar, 'شورت كارجو أسود');
    });

    test('starts empty rather than throwing on unreadable storage', () async {
      // A cart written by an older build, or corrupted storage. Losing it
      // costs a re-add; throwing here would take down the storefront on
      // launch.
      final container = await buildContainer(
        initialStore: {'sxh_store_cart_v1': 'not json at all'},
      );
      addTearDown(container.dispose);

      expect(container.read(cartControllerProvider), isEmpty);
    });

    test('clear empties both memory and storage', () async {
      final container = await buildContainer();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);
      await cart.add(product, large);

      await cart.clear();

      expect(container.read(cartControllerProvider), isEmpty);
      final stored = container
          .read(cartPreferencesProvider)
          .getString('sxh_store_cart_v1');
      expect(jsonDecode(stored!), isEmpty);
    });
  });
}
