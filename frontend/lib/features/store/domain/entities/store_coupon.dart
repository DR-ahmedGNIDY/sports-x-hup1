enum CouponType {
  /// [value] is whole percent — 10 means 10% off the subtotal.
  percent,

  /// [value] is piastres off, like every other amount in the store.
  fixed;

  static CouponType fromJson(String raw) =>
      raw == 'fixed' ? CouponType.fixed : CouponType.percent;

  String get wireValue => name;
}

/// A discount code, as the dashboard sees it.
///
/// There is no customer-facing equivalent: a shopper only ever learns
/// whether the one code they typed is valid and what it takes off, never
/// that the others exist.
class StoreCoupon {
  const StoreCoupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.minSubtotalMinor,
    required this.redemptions,
    required this.isActive,
    this.maxRedemptions,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String code;
  final CouponType type;
  final int value;
  final int minSubtotalMinor;

  /// How many times it has been used. Held by the server, which increments
  /// it as part of claiming the code, so it is read-only here.
  final int redemptions;

  /// Null means unlimited — the common case for an open campaign code.
  final int? maxRedemptions;

  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;

  bool get isExhausted {
    final cap = maxRedemptions;
    return cap != null && redemptions >= cap;
  }

  /// Whether a customer could use it right now. Mirrors the server's own
  /// checks so the dashboard can show why a live code is not working
  /// without anyone having to try it.
  bool isUsableAt(DateTime now) =>
      isActive &&
      !isExhausted &&
      (startsAt == null || !startsAt!.isAfter(now)) &&
      (endsAt == null || !endsAt!.isBefore(now));
}

/// What a code is worth against one basket, as the cart's preview returns it.
class CouponQuote {
  const CouponQuote({required this.code, required this.discountMinor});

  final String code;
  final int discountMinor;
}
