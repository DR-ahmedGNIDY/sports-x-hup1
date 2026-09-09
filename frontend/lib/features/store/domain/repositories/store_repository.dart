import '../entities/cart_item.dart';
import '../entities/product_list_page.dart';
import '../entities/shipping_zone.dart';
import '../entities/store_banner.dart';
import '../entities/store_category.dart';
import '../entities/store_coupon.dart';
import '../entities/store_order.dart';
import '../entities/store_product.dart';

abstract class StoreRepository {
  Future<List<StoreCategory>> listCategories();

  Future<ProductListPage> listProducts({
    int page,
    String? search,
    String? categoryId,
    String? categorySlug,
    String? size,
    String? colour,
    int? minPriceMinor,
    int? maxPriceMinor,
    bool? featured,
    String? sort,
  });

  Future<StoreProduct> getProductBySlug(String slug);

  /// The hero's slides, in the merchant's order.
  Future<List<StoreBanner>> listBanners();

  Future<List<ShippingZone>> listShippingZones();

  /// Places the order. [items] carries only ids and quantities — the server
  /// prices every line itself, so nothing here can influence what is
  /// charged. Works with or without a session: signed in, the order joins
  /// the customer's history; otherwise it is a guest order.
  Future<StoreOrder> placeOrder({
    required String email,
    required List<CartItem> items,
    required String fullName,
    required String phone,
    required String governorateCode,
    required String city,
    required String street,
    String? notes,
    // A code, never a discount amount — the server decides what it is worth.
    String? couponCode,
  });

  /// Prices a discount code for the cart. Throws with the server's own
  /// message when the code cannot be used — "expired" and "your basket is
  /// too small" are different problems and only one is solvable.
  Future<CouponQuote> previewCoupon({
    required String code,
    required int subtotalMinor,
  });

  /// Guest retrieval: the order number plus the email it was placed with.
  Future<StoreOrder> trackOrder({
    required String orderNumber,
    required String email,
  });

  /// The signed-in customer's own orders.
  Future<List<StoreOrder>> listMyOrders({int page});
}
