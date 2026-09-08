import '../entities/cart_item.dart';
import '../entities/product_list_page.dart';
import '../entities/shipping_zone.dart';
import '../entities/store_category.dart';
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
  });

  /// Guest retrieval: the order number plus the email it was placed with.
  Future<StoreOrder> trackOrder({
    required String orderNumber,
    required String email,
  });

  /// The signed-in customer's own orders.
  Future<List<StoreOrder>> listMyOrders({int page});
}
