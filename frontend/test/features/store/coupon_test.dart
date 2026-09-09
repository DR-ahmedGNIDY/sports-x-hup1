import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/store/data/models/store_models.dart';
import 'package:sport_x_hub/features/store/domain/entities/store_coupon.dart';
import 'package:sport_x_hub/features/store/domain/entities/store_overview.dart';

void main() {
  group('StoreCouponModel', () {
    Map<String, dynamic> couponJson([Map<String, dynamic> overrides = const {}]) => {
      'id': 'c1',
      'code': 'SUMMER10',
      'type': 'percent',
      'value': 10,
      'minSubtotalMinor': 50000,
      'redemptions': 3,
      'isActive': true,
      ...overrides,
    };

    test('parses a percentage coupon', () {
      final coupon = StoreCouponModel.fromJson(couponJson());
      expect(coupon.type, CouponType.percent);
      expect(coupon.value, 10);
      expect(coupon.minSubtotalMinor, 50000);
    });

    test('parses a fixed-amount coupon', () {
      final coupon = StoreCouponModel.fromJson(
        couponJson({'type': 'fixed', 'value': 5000}),
      );
      expect(coupon.type, CouponType.fixed);
      // 5000 piastres is 50 EGP off, not 5000% — the type is what
      // disambiguates the same integer.
      expect(coupon.value, 5000);
    });

    test('treats a missing limit as unlimited, not as zero', () {
      final coupon = StoreCouponModel.fromJson(couponJson());
      expect(coupon.maxRedemptions, isNull);
      // Zero would read as "exhausted" and hide a perfectly live code.
      expect(coupon.isExhausted, isFalse);
    });

    test('parses dates, and tolerates their absence', () {
      final dated = StoreCouponModel.fromJson(
        couponJson({
          'startsAt': '2026-06-01T00:00:00.000Z',
          'endsAt': '2026-07-01T00:00:00.000Z',
        }),
      );
      expect(dated.startsAt?.year, 2026);
      expect(dated.endsAt?.month, 7);

      final undated = StoreCouponModel.fromJson(couponJson());
      expect(undated.startsAt, isNull);
      expect(undated.endsAt, isNull);
    });

    test('parses the cart quote', () {
      final quote = StoreCouponModel.quoteFromJson({
        'code': 'SUMMER10',
        'discountMinor': 7400,
      });
      expect(quote.code, 'SUMMER10');
      expect(quote.discountMinor, 7400);
    });
  });

  // The dashboard shows one word per code for the state a customer would
  // actually hit. These mirror the server's own checks.
  group('coupon usability', () {
    final now = DateTime(2026, 6, 15);

    StoreCoupon coupon({
      bool isActive = true,
      int redemptions = 0,
      int? maxRedemptions,
      DateTime? startsAt,
      DateTime? endsAt,
    }) => StoreCoupon(
      id: 'c1',
      code: 'SUMMER10',
      type: CouponType.percent,
      value: 10,
      minSubtotalMinor: 0,
      redemptions: redemptions,
      maxRedemptions: maxRedemptions,
      startsAt: startsAt,
      endsAt: endsAt,
      isActive: isActive,
    );

    test('an open-ended active code is usable', () {
      expect(coupon().isUsableAt(now), isTrue);
    });

    test('a deactivated code is not, whatever its dates say', () {
      expect(coupon(isActive: false).isUsableAt(now), isFalse);
    });

    test('a code is not usable before its start', () {
      expect(
        coupon(startsAt: DateTime(2026, 7, 1)).isUsableAt(now),
        isFalse,
      );
    });

    test('a code is not usable after its end', () {
      expect(coupon(endsAt: DateTime(2026, 6, 1)).isUsableAt(now), isFalse);
    });

    test('the boundaries are inclusive', () {
      // A code that says it runs until the 15th should work on the 15th.
      expect(coupon(startsAt: now, endsAt: now).isUsableAt(now), isTrue);
    });

    test('a fully redeemed code is not usable', () {
      expect(
        coupon(redemptions: 5, maxRedemptions: 5).isUsableAt(now),
        isFalse,
      );
    });

    test('a code with redemptions left is still usable', () {
      expect(
        coupon(redemptions: 4, maxRedemptions: 5).isUsableAt(now),
        isTrue,
      );
    });
  });

  group('StoreOverview', () {
    test('parses the dashboard numbers', () {
      final overview = StoreOverview.fromJson({
        'ordersToday': 3,
        'revenueTodayMinor': 241500,
        'pendingOrders': 2,
        'outOfStockProducts': 1,
        'lowStockProducts': 4,
        'activeProducts': 12,
      });

      expect(overview.ordersToday, 3);
      expect(overview.revenueTodayMinor, 241500);
      expect(overview.pendingOrders, 2);
      expect(overview.lowStockProducts, 4);
    });

    test('reads a missing field as zero rather than throwing', () {
      // A quiet day returns zeroes, but an older server might omit a newer
      // field entirely; the dashboard should still render.
      final overview = StoreOverview.fromJson({});
      expect(overview.ordersToday, 0);
      expect(overview.revenueTodayMinor, 0);
      expect(overview.activeProducts, 0);
    });
  });
}
