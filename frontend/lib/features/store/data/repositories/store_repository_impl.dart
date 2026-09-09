import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product_list_page.dart';
import '../../domain/entities/shipping_zone.dart';
import '../../domain/entities/store_banner.dart';
import '../../domain/entities/store_category.dart';
import '../../domain/entities/store_coupon.dart';
import '../../domain/entities/store_order.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_remote_data_source.dart';
import '../models/store_models.dart';

class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl(this._remote, this._storage, this._ref);

  final StoreRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  @override
  Future<List<StoreCategory>> listCategories() async {
    final json = await _remote.listCategories();
    return (json['items'] as List<dynamic>)
        .map((e) => StoreCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProductListPage> listProducts({
    int page = 1,
    String? search,
    String? categoryId,
    String? categorySlug,
    String? size,
    String? colour,
    int? minPriceMinor,
    int? maxPriceMinor,
    bool? featured,
    String? sort,
  }) async {
    // Absent filters are omitted rather than sent empty: the backend's
    // validation treats an empty string as a value to match on.
    final query = <String, String>{
      'page': '$page',
      'search': ?search,
      'categoryId': ?categoryId,
      'categorySlug': ?categorySlug,
      'size': ?size,
      'colour': ?colour,
      'minPriceMinor': ?minPriceMinor?.toString(),
      'maxPriceMinor': ?maxPriceMinor?.toString(),
      'featured': ?featured?.toString(),
      'sort': ?sort,
    };
    return StoreProductModel.pageFromJson(await _remote.listProducts(query));
  }

  @override
  Future<StoreProduct> getProductBySlug(String slug) async =>
      StoreProductModel.fromJson(await _remote.getProductBySlug(slug));

  @override
  Future<List<StoreBanner>> listBanners() async {
    final json = await _remote.listBanners();
    return (json['items'] as List<dynamic>)
        .map((e) => StoreBannerModel.fromJson(e as Map<String, dynamic>))
        // A slide the parser refused (no desktop image) is dropped rather
        // than rendered empty.
        .nonNulls
        .toList();
  }

  @override
  Future<List<ShippingZone>> listShippingZones() async {
    final json = await _remote.listShippingZones();
    return (json['items'] as List<dynamic>)
        .map((e) => ShippingZoneModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StoreOrder> placeOrder({
    required String email,
    required List<CartItem> items,
    required String fullName,
    required String phone,
    required String governorateCode,
    required String city,
    required String street,
    String? notes,
    String? couponCode,
  }) async {
    final body = {
      'email': email,
      // Ids and quantities only — no prices. The server decides what this
      // costs; anything sent from here would be a number to ignore.
      'lines': items
          .map(
            (item) => {
              'productId': item.productId,
              'variantId': item.variantId,
              'quantity': item.quantity,
            },
          )
          .toList(),
      if (couponCode != null && couponCode.isNotEmpty)
        'couponCode': couponCode,
      'address': {
        'fullName': fullName,
        'phone': phone,
        'governorateCode': governorateCode,
        'city': city,
        'street': street,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    };

    // Deliberately not `runAuthorized`: that throws when there is no
    // session, and a guest checkout has none. A signed-in customer's token
    // is attached opportunistically so their order joins their history, and
    // a checkout must never fail merely because a token expired — the
    // backend treats a bad token as no token for exactly this reason.
    final accessToken = await _storage.accessToken;
    return StoreOrderModel.fromJson(
      await _remote.placeOrder(body, accessToken: accessToken),
    );
  }

  @override
  Future<CouponQuote> previewCoupon({
    required String code,
    required int subtotalMinor,
  }) async => StoreCouponModel.quoteFromJson(
    await _remote.previewCoupon(code: code, subtotalMinor: subtotalMinor),
  );

  @override
  Future<StoreOrder> trackOrder({
    required String orderNumber,
    required String email,
  }) async => StoreOrderModel.fromJson(
    await _remote.trackOrder(orderNumber: orderNumber, email: email),
  );

  @override
  Future<List<StoreOrder>> listMyOrders({int page = 1}) async {
    final json = await runAuthorized(
      _ref,
      _storage,
      (token) => _remote.listMyOrders(token, page: page),
    );
    return (json['items'] as List<dynamic>)
        .map((e) => StoreOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => StoreRepositoryImpl(
    ref.watch(storeRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
