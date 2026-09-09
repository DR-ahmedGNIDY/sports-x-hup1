import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../../store/data/models/store_models.dart';
import '../../../store/domain/entities/product_list_page.dart';
import '../../../store/domain/entities/shipping_zone.dart';
import '../../../store/domain/entities/store_category.dart';
import '../../../store/domain/entities/store_coupon.dart';
import '../../../store/domain/entities/store_overview.dart';
import '../../../store/domain/entities/store_order.dart';
import '../../../store/domain/entities/store_product.dart';
import '../datasources/admin_store_data_source.dart';

/// The merchant's view of the store.
///
/// It reuses the storefront's entities and parsers rather than declaring its
/// own: the admin responses are supersets of the public ones (they add
/// `stock` and `isActive`), so a second set of models would be the same
/// shapes maintained twice.
class AdminStoreRepositoryImpl {
  AdminStoreRepositoryImpl(this._remote, this._storage, this._ref);

  final AdminStoreDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(Future<T> Function(String token) call) =>
      runAuthorized(_ref, _storage, call);

  // ---------------------------------------------------------------- products

  Future<ProductListPage> listProducts({int page = 1, String? search}) async {
    final json = await _authorized(
      (token) => _remote.listProducts(token, page: page, search: search),
    );
    return StoreProductModel.pageFromJson(json);
  }

  Future<StoreProduct> createProduct(Map<String, dynamic> body) async =>
      StoreProductModel.fromJson(
        await _authorized((token) => _remote.createProduct(token, body)),
      );

  Future<StoreProduct> updateProduct(
    String id,
    Map<String, dynamic> body,
  ) async => StoreProductModel.fromJson(
    await _authorized((token) => _remote.updateProduct(token, id, body)),
  );

  Future<StoreProduct> deactivateProduct(String id) async =>
      StoreProductModel.fromJson(
        await _authorized((token) => _remote.deactivateProduct(token, id)),
      );

  Future<StoreProduct> addProductImage(
    String id,
    List<int> bytes,
    String filename,
  ) async => StoreProductModel.fromJson(
    await _authorized(
      (token) => _remote.addProductImage(token, id, bytes, filename),
    ),
  );

  Future<StoreProduct> removeProductImage(String id, String publicId) async =>
      StoreProductModel.fromJson(
        await _authorized(
          (token) => _remote.removeProductImage(token, id, publicId),
        ),
      );

  // -------------------------------------------------------------- categories

  Future<List<StoreCategory>> listCategories() async {
    final json = await _authorized(_remote.listCategories);
    return (json['items'] as List<dynamic>)
        .map((e) => StoreCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StoreCategory> createCategory(Map<String, dynamic> body) async =>
      StoreCategoryModel.fromJson(
        await _authorized((token) => _remote.createCategory(token, body)),
      );

  Future<StoreCategory> updateCategory(
    String id,
    Map<String, dynamic> body,
  ) async => StoreCategoryModel.fromJson(
    await _authorized((token) => _remote.updateCategory(token, id, body)),
  );

  Future<StoreCategory> setCategoryImage(
    String id,
    List<int> bytes,
    String filename,
  ) async => StoreCategoryModel.fromJson(
    await _authorized(
      (token) => _remote.setCategoryImage(token, id, bytes, filename),
    ),
  );

  // ------------------------------------------------------------------ orders

  Future<({List<StoreOrder> items, bool hasMore})> listOrders({
    int page = 1,
    String? status,
  }) async {
    final json = await _authorized(
      (token) => _remote.listOrders(token, page: page, status: status),
    );
    final items = (json['items'] as List<dynamic>)
        .map((e) => StoreOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = json['total'] as int;
    final pageSize = json['pageSize'] as int;
    return (items: items, hasMore: (json['page'] as int) * pageSize < total);
  }

  Future<StoreOrder> setOrderStatus(String id, String status) async =>
      StoreOrderModel.fromJson(
        await _authorized((token) => _remote.setOrderStatus(token, id, status)),
      );

  // ---------------------------------------------------------------- overview

  Future<StoreOverview> overview() async =>
      StoreOverview.fromJson(await _authorized(_remote.overview));

  // ----------------------------------------------------------------- coupons

  Future<List<StoreCoupon>> listCoupons() async {
    final json = await _authorized(_remote.listCoupons);
    return (json['items'] as List<dynamic>)
        .map((e) => StoreCouponModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StoreCoupon> createCoupon(Map<String, dynamic> body) async =>
      StoreCouponModel.fromJson(
        await _authorized((token) => _remote.createCoupon(token, body)),
      );

  Future<StoreCoupon> updateCoupon(
    String id,
    Map<String, dynamic> body,
  ) async => StoreCouponModel.fromJson(
    await _authorized((token) => _remote.updateCoupon(token, id, body)),
  );

  // ---------------------------------------------------------------- shipping

  Future<List<ShippingZone>> listShippingZones() async {
    final json = await _authorized(_remote.listShippingZones);
    return (json['items'] as List<dynamic>)
        .map((e) => ShippingZoneModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ShippingZone> updateShippingZone(
    String id,
    Map<String, dynamic> body,
  ) async => ShippingZoneModel.fromJson(
    await _authorized((token) => _remote.updateShippingZone(token, id, body)),
  );
}

final adminStoreRepositoryProvider = Provider<AdminStoreRepositoryImpl>(
  (ref) => AdminStoreRepositoryImpl(
    ref.watch(adminStoreDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
