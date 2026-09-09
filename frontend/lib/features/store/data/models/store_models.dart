import '../../domain/entities/localized_text.dart';
import '../../domain/entities/product_list_page.dart';
import '../../domain/entities/shipping_zone.dart';
import '../../domain/entities/store_category.dart';
import '../../domain/entities/store_coupon.dart';
import '../../domain/entities/store_order.dart';
import '../../domain/entities/store_product.dart';

/// Wire-format parsing for the whole store feature.
///
/// One file rather than one per entity: these are all views of the same
/// endpoint family, they share [_localized] and the money/optional-field
/// conventions, and splitting them would mean six files that only ever
/// change together.
LocalizedText _localized(Map<String, dynamic> json) => LocalizedText(
  en: json['en'] as String,
  ar: json['ar'] as String?,
);

class StoreCategoryModel {
  static StoreCategory fromJson(Map<String, dynamic> json) => StoreCategory(
    id: json['id'] as String,
    name: _localized(json['name'] as Map<String, dynamic>),
    slug: json['slug'] as String,
    parentId: json['parentId'] as String?,
    imageUrl: (json['image'] as Map<String, dynamic>?)?['secureUrl'] as String?,
    sortOrder: json['sortOrder'] as int? ?? 0,
    isActive: json['isActive'] as bool?,
  );
}

class StoreProductModel {
  /// Handles both shapes the API returns: the card view (no `variants`, one
  /// `image`) and the detail view (`images` and `variants` present). The
  /// difference is absence, not a discriminator, so the same parser covers
  /// both rather than guessing which endpoint produced it.
  static StoreProduct fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    final images = (json['images'] as List<dynamic>?)
        ?.map(
          (e) => ProductImage(
            publicId: (e as Map<String, dynamic>)['publicId'] as String,
            url: e['secureUrl'] as String,
          ),
        )
        .toList();

    return StoreProduct(
      id: json['id'] as String,
      title: _localized(json['title'] as Map<String, dynamic>),
      slug: json['slug'] as String,
      priceMinor: json['priceMinor'] as int,
      compareAtPriceMinor: json['compareAtPriceMinor'] as int?,
      inStock: json['inStock'] as bool? ?? false,
      imageUrl: image?['secureUrl'] as String? ?? images?.firstOrNull?.url,
      badge: ProductBadge.fromJson(json['badge'] as String?),
      description: json['description'] == null
          ? null
          : _localized(json['description'] as Map<String, dynamic>),
      images: images ?? const [],
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map((e) => _variant(e as Map<String, dynamic>))
              .toList() ??
          const [],
      categoryId: json['categoryId'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      isFeatured: json['isFeatured'] as bool? ?? false,
      isActive: json['isActive'] as bool?,
    );
  }

  // The admin view sends `stock` and no `inStock`; the public view sends
  // the reverse. Deriving one from the other rather than requiring both
  // means a single parser serves them, and the admin still gets a usable
  // `inStock` for the shared widgets.
  static ProductVariant _variant(Map<String, dynamic> json) => ProductVariant(
    id: json['id'] as String,
    stock: json['stock'] as int?,
    inStock:
        json['inStock'] as bool? ??
        ((json['stock'] as int?) ?? 0) > 0,
    size: json['size'] as String?,
    colour: json['colour'] as String?,
    sku: json['sku'] as String?,
  );

  static ProductListPage pageFromJson(Map<String, dynamic> json) =>
      ProductListPage(
        items: (json['items'] as List<dynamic>)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        total: json['total'] as int,
      );
}

class ShippingZoneModel {
  static ShippingZone fromJson(Map<String, dynamic> json) => ShippingZone(
    id: json['id'] as String,
    name: _localized(json['name'] as Map<String, dynamic>),
    code: json['code'] as String,
    feeMinor: json['feeMinor'] as int,
    isActive: json['isActive'] as bool?,
  );
}

class StoreOrderModel {
  static StoreOrder fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>;
    return StoreOrder(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      email: json['email'] as String,
      status: OrderStatus.fromJson(json['status'] as String),
      userId: json['userId'] as String?,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => _line(e as Map<String, dynamic>))
          .toList(),
      address: OrderAddress(
        fullName: address['fullName'] as String,
        phone: address['phone'] as String,
        governorateCode: address['governorateCode'] as String,
        governorateName: _localized(
          address['governorateName'] as Map<String, dynamic>,
        ),
        city: address['city'] as String,
        street: address['street'] as String,
        notes: address['notes'] as String?,
      ),
      subtotalMinor: json['subtotalMinor'] as int,
      shippingFeeMinor: json['shippingFeeMinor'] as int,
      totalMinor: json['totalMinor'] as int,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  static OrderLine _line(Map<String, dynamic> json) => OrderLine(
    productId: json['productId'] as String,
    variantId: json['variantId'] as String,
    title: _localized(json['title'] as Map<String, dynamic>),
    quantity: json['quantity'] as int,
    unitPriceMinor: json['unitPriceMinor'] as int,
    size: json['size'] as String?,
    colour: json['colour'] as String?,
    imageUrl: json['imageUrl'] as String?,
  );
}

class StoreCouponModel {
  static StoreCoupon fromJson(Map<String, dynamic> json) => StoreCoupon(
    id: json['id'] as String,
    code: json['code'] as String,
    type: CouponType.fromJson(json['type'] as String),
    value: json['value'] as int,
    minSubtotalMinor: json['minSubtotalMinor'] as int? ?? 0,
    redemptions: json['redemptions'] as int? ?? 0,
    maxRedemptions: json['maxRedemptions'] as int?,
    startsAt: _date(json['startsAt']),
    endsAt: _date(json['endsAt']),
    isActive: json['isActive'] as bool? ?? true,
  );

  static CouponQuote quoteFromJson(Map<String, dynamic> json) => CouponQuote(
    code: json['code'] as String,
    discountMinor: json['discountMinor'] as int,
  );
}

/// Dates arrive as ISO strings, or not at all for an open-ended campaign.
DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
