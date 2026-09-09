import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/domain/entities/admin_banner.dart';
import '../../store/domain/entities/shipping_zone.dart';
import '../../store/domain/entities/store_category.dart';
import '../../store/domain/entities/store_coupon.dart';
import '../../store/domain/entities/store_overview.dart';
import '../../store/domain/entities/store_order.dart';
import '../../store/domain/entities/store_product.dart';
import '../data/repositories/admin_store_repository_impl.dart';

/// Products, including the unlisted ones. Paged, and every mutation
/// invalidates rather than patching the list in place: a create allocates a
/// slug and an update can change which page a product falls on, so the
/// server's ordering is the only one worth trusting.
class AdminProductsController extends AsyncNotifier<List<StoreProduct>> {
  int _page = 1;
  String? _search;
  bool hasMore = false;

  @override
  Future<List<StoreProduct>> build() => _load(1, _search);

  Future<List<StoreProduct>> _load(int page, String? search) async {
    final result = await ref
        .read(adminStoreRepositoryProvider)
        .listProducts(page: page, search: search);
    _page = page;
    _search = search;
    hasMore = result.hasMore;
    return result.items;
  }

  Future<void> search(String? term) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(1, term));
  }

  Future<void> loadMore() async {
    if (!hasMore || state.isLoading) return;
    final more = await _load(_page + 1, _search);
    state = AsyncData([...?state.valueOrNull, ...more]);
  }

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(adminStoreRepositoryProvider).createProduct(body);
    await _reload();
  }

  Future<void> save(String id, Map<String, dynamic> body) async {
    await ref.read(adminStoreRepositoryProvider).updateProduct(id, body);
    await _reload();
  }

  Future<void> deactivate(String id) async {
    await ref.read(adminStoreRepositoryProvider).deactivateProduct(id);
    await _reload();
  }

  Future<StoreProduct> addImage(
    String id,
    List<int> bytes,
    String filename,
  ) async {
    final updated = await ref
        .read(adminStoreRepositoryProvider)
        .addProductImage(id, bytes, filename);
    await _reload();
    // Returned as well as reloaded so the editor dialog can show the new
    // gallery without waiting for the table behind it.
    return updated;
  }

  Future<StoreProduct> removeImage(String id, String publicId) async {
    final updated = await ref
        .read(adminStoreRepositoryProvider)
        .removeProductImage(id, publicId);
    await _reload();
    return updated;
  }

  // Re-reads the page the merchant is looking at, not page 1 — being sent
  // back to the top after editing row 40 is its own small hostility.
  Future<void> _reload() async {
    state = await AsyncValue.guard(() => _load(_page, _search));
  }
}

final adminProductsControllerProvider =
    AsyncNotifierProvider<AdminProductsController, List<StoreProduct>>(
      AdminProductsController.new,
    );

class AdminCategoriesController extends AsyncNotifier<List<StoreCategory>> {
  @override
  Future<List<StoreCategory>> build() =>
      ref.read(adminStoreRepositoryProvider).listCategories();

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(adminStoreRepositoryProvider).createCategory(body);
    ref.invalidateSelf();
    await future;
  }

  Future<void> save(String id, Map<String, dynamic> body) async {
    await ref.read(adminStoreRepositoryProvider).updateCategory(id, body);
    ref.invalidateSelf();
    await future;
  }

  Future<void> setImage(String id, List<int> bytes, String filename) async {
    await ref
        .read(adminStoreRepositoryProvider)
        .setCategoryImage(id, bytes, filename);
    ref.invalidateSelf();
    await future;
  }
}

final adminCategoriesControllerProvider =
    AsyncNotifierProvider<AdminCategoriesController, List<StoreCategory>>(
      AdminCategoriesController.new,
    );

/// The order queue. [filter] is null for "everything", which is the state
/// the merchant opens on — a queue that hides orders by default is how one
/// gets missed.
class AdminOrdersController extends AsyncNotifier<List<StoreOrder>> {
  int _page = 1;
  OrderStatus? _filter;
  bool hasMore = false;

  OrderStatus? get filter => _filter;

  @override
  Future<List<StoreOrder>> build() => _load(1, null);

  Future<List<StoreOrder>> _load(int page, OrderStatus? status) async {
    final result = await ref
        .read(adminStoreRepositoryProvider)
        .listOrders(page: page, status: status?.name);
    _page = page;
    _filter = status;
    hasMore = result.hasMore;
    return result.items;
  }

  Future<void> setFilter(OrderStatus? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(1, status));
  }

  Future<void> loadMore() async {
    if (!hasMore || state.isLoading) return;
    final more = await _load(_page + 1, _filter);
    state = AsyncData([...?state.valueOrNull, ...more]);
  }

  /// Advancing an order can move it out of the current filter, and
  /// cancelling returns stock, so the list is re-read rather than patched.
  Future<void> setStatus(String id, OrderStatus status) async {
    await ref
        .read(adminStoreRepositoryProvider)
        .setOrderStatus(id, status.name);
    state = await AsyncValue.guard(() => _load(_page, _filter));
  }
}

final adminOrdersControllerProvider =
    AsyncNotifierProvider<AdminOrdersController, List<StoreOrder>>(
      AdminOrdersController.new,
    );

class AdminShippingController extends AsyncNotifier<List<ShippingZone>> {
  @override
  Future<List<ShippingZone>> build() =>
      ref.read(adminStoreRepositoryProvider).listShippingZones();

  /// The API refuses a changed `code` — it is the identity past orders were
  /// written against — so the zone's own code is always sent back unchanged.
  Future<void> save(
    ShippingZone zone, {
    required int feeMinor,
    required bool isActive,
  }) async {
    await ref.read(adminStoreRepositoryProvider).updateShippingZone(zone.id, {
      'name': {'en': zone.name.en, 'ar': zone.name.ar},
      'code': zone.code,
      'feeMinor': feeMinor,
      'isActive': isActive,
    });
    ref.invalidateSelf();
    await future;
  }
}

final adminShippingControllerProvider =
    AsyncNotifierProvider<AdminShippingController, List<ShippingZone>>(
      AdminShippingController.new,
    );

/// The dashboard's headline numbers. A one-shot read rather than a polling
/// stream — the merchant refreshes by revisiting the tab, and a store this
/// size does not need a live ticker.
final adminStoreOverviewProvider = FutureProvider<StoreOverview>(
  (ref) => ref.read(adminStoreRepositoryProvider).overview(),
);

class AdminCouponsController extends AsyncNotifier<List<StoreCoupon>> {
  @override
  Future<List<StoreCoupon>> build() =>
      ref.read(adminStoreRepositoryProvider).listCoupons();

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(adminStoreRepositoryProvider).createCoupon(body);
    ref.invalidateSelf();
    await future;
  }

  Future<void> save(String id, Map<String, dynamic> body) async {
    await ref.read(adminStoreRepositoryProvider).updateCoupon(id, body);
    ref.invalidateSelf();
    await future;
  }
}

final adminCouponsControllerProvider =
    AsyncNotifierProvider<AdminCouponsController, List<StoreCoupon>>(
      AdminCouponsController.new,
    );


/// The hero's slides, including the unfinished ones the storefront hides.
class AdminBannersController extends AsyncNotifier<List<AdminBanner>> {
  @override
  Future<List<AdminBanner>> build() =>
      ref.read(adminStoreRepositoryProvider).listBanners();

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(adminStoreRepositoryProvider).createBanner(body);
    await _reload();
  }

  Future<void> save(String id, Map<String, dynamic> body) async {
    await ref.read(adminStoreRepositoryProvider).updateBanner(id, body);
    await _reload();
  }

  Future<void> setImage(
    String id,
    String slot,
    List<int> bytes,
    String filename,
  ) async {
    await ref
        .read(adminStoreRepositoryProvider)
        .setBannerImage(id, slot, bytes, filename);
    await _reload();
  }

  Future<void> removeImage(String id, String slot) async {
    await ref.read(adminStoreRepositoryProvider).removeBannerImage(id, slot);
    await _reload();
  }

  Future<void> deactivate(String id) async {
    await ref.read(adminStoreRepositoryProvider).deactivateBanner(id);
    await _reload();
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }
}

final adminBannersControllerProvider =
    AsyncNotifierProvider<AdminBannersController, List<AdminBanner>>(
      AdminBannersController.new,
    );
