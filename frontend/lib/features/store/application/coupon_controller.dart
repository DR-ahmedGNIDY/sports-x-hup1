import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/repositories/store_repository_impl.dart';
import '../domain/entities/store_coupon.dart';
import 'cart_controller.dart';

/// A code the customer has typed into the cart, and what the server said
/// about it.
///
/// [quote] is indicative only. The code is claimed and re-priced at
/// checkout against the server's own subtotal, so what shows here can never
/// decide what is actually charged — it only tells the customer whether
/// typing it was worth it.
class CouponState {
  const CouponState({this.isChecking = false, this.quote, this.error});

  final bool isChecking;
  final CouponQuote? quote;
  final String? error;

  bool get isApplied => quote != null;
}

final couponControllerProvider =
    NotifierProvider<CouponController, CouponState>(CouponController.new);

class CouponController extends Notifier<CouponState> {
  @override
  CouponState build() => const CouponState();

  Future<void> apply(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    final subtotalMinor = ref.read(cartSubtotalMinorProvider);
    state = const CouponState(isChecking: true);
    try {
      final quote = await ref
          .read(storeRepositoryProvider)
          .previewCoupon(code: code, subtotalMinor: subtotalMinor);
      state = CouponState(quote: quote);
    } on AppException catch (error) {
      // The server's message, not a generic one: it distinguishes an
      // expired code from a basket below the minimum, and only the second
      // is something the customer can act on.
      state = CouponState(error: error.message);
    }
  }

  void clear() => state = const CouponState();
}

/// What the cart shows as the discount. Recomputed against the current
/// subtotal is deliberately *not* attempted here — a percentage quote taken
/// at one basket size is stale once the basket changes, so the cart drops
/// the code instead. See [CouponController.clear]'s callers.
final cartDiscountMinorProvider = Provider<int>((ref) {
  final quote = ref.watch(couponControllerProvider).quote;
  final subtotal = ref.watch(cartSubtotalMinorProvider);
  if (quote == null) return 0;
  // Still floored at the basket, in case the basket shrank between the
  // quote and this read.
  return quote.discountMinor > subtotal ? subtotal : quote.discountMinor;
});
