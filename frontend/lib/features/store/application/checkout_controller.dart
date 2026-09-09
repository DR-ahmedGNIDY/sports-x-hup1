import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/repositories/store_repository_impl.dart';
import '../domain/entities/store_order.dart';
import 'cart_controller.dart';
import 'coupon_controller.dart';

/// Where a checkout attempt is. [order] is set only on success, and is what
/// the confirmation screen renders — including the order number a guest
/// needs in order to find this order again.
class CheckoutState {
  const CheckoutState({this.isSubmitting = false, this.order, this.error});

  final bool isSubmitting;
  final StoreOrder? order;
  final String? error;

  bool get isDone => order != null;
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(
      CheckoutController.new,
    );

class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  Future<StoreOrder?> submit({
    required String email,
    required String fullName,
    required String phone,
    required String governorateCode,
    required String city,
    required String street,
    String? notes,
  }) async {
    final items = ref.read(cartControllerProvider);
    if (items.isEmpty) {
      state = const CheckoutState(error: 'Your cart is empty.');
      return null;
    }

    state = const CheckoutState(isSubmitting: true);
    try {
      final order = await ref
          .read(storeRepositoryProvider)
          .placeOrder(
            email: email,
            items: items,
            fullName: fullName,
            phone: phone,
            governorateCode: governorateCode,
            city: city,
            street: street,
            notes: notes,
            // The code, not the discount — the server re-prices it against
            // its own subtotal, and that answer is what gets charged.
            couponCode: ref.read(couponControllerProvider).quote?.code,
          );

      // Cleared only once the server has confirmed the order. Clearing
      // optimistically would lose a customer's whole basket on a network
      // failure, with nothing to show for it.
      await ref.read(cartControllerProvider.notifier).clear();
      ref.read(couponControllerProvider.notifier).clear();

      state = CheckoutState(order: order);
      return order;
    } on AppException catch (error) {
      // A 409 here is the stock race the backend guards: something in the
      // cart sold out between browsing and paying. The message is the
      // server's, because it is the only thing that knows which item.
      state = CheckoutState(error: error.message);
      return null;
    }
  }

  /// Lets the checkout screen be reopened after a failure without carrying
  /// the previous attempt's error banner.
  void reset() => state = const CheckoutState();
}

/// Guest order lookup: order number plus the email it was placed with.
final trackedOrderProvider =
    FutureProvider.family<StoreOrder, ({String orderNumber, String email})>((
      ref,
      credentials,
    ) {
      return ref
          .read(storeRepositoryProvider)
          .trackOrder(
            orderNumber: credentials.orderNumber,
            email: credentials.email,
          );
    });

/// The signed-in customer's own orders. Guests have none — they use the
/// tracking form above instead.
final myOrdersProvider = FutureProvider<List<StoreOrder>>(
  (ref) => ref.watch(storeRepositoryProvider).listMyOrders(),
);
