import 'localized_text.dart';

/// The small corner label on a product card. Unknown values from a newer
/// backend degrade to [none] rather than throwing — a card that cannot name
/// its badge should still render.
enum ProductBadge {
  none,
  isNew,
  preOrder,
  sale;

  static ProductBadge fromJson(String? raw) => switch (raw) {
    'new' => ProductBadge.isNew,
    'pre_order' => ProductBadge.preOrder,
    'sale' => ProductBadge.sale,
    _ => ProductBadge.none,
  };
}

/// One image in a product's gallery.
///
/// Carries the Cloudinary [publicId] as well as the URL because that id is
/// how the admin API addresses an image for deletion. Deriving it from the
/// URL would work until Cloudinary changed its URL shape.
class ProductImage {
  const ProductImage({required this.publicId, required this.url});

  final String publicId;
  final String url;
}

/// One buyable combination.
///
/// [inStock] is always known; [stock] usually is not. The public API sends
/// only whether an option can be bought, so a storefront client holds no
/// number it could leak — the count arrives solely on the admin views.
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.inStock,
    this.size,
    this.colour,
    this.sku,
    this.stock,
  });

  final String id;
  final bool inStock;

  /// The real count. Null on every public response — the storefront is only
  /// told whether an option can be bought — and populated for the admin,
  /// which is the one caller entitled to the number.
  final int? stock;
  final String? size;
  final String? colour;
  final String? sku;

  /// "L · Black", in whichever halves exist.
  String label() =>
      [?size, ?colour].where((part) => part.isNotEmpty).join(' · ');
}

/// A product as a card renders it. [variants] is empty for the card view —
/// the listing endpoint omits it — and populated for the detail view.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.slug,
    required this.priceMinor,
    required this.inStock,
    this.compareAtPriceMinor,
    this.imageUrl,
    this.badge = ProductBadge.none,
    this.description,
    this.images = const [],
    this.variants = const [],
    this.categoryId,
    this.tags = const [],
    this.isFeatured = false,
    this.isActive,
  });

  final String id;
  final LocalizedText title;
  final String slug;

  /// Piastres, matching the API. Formatting happens at the widget, where the
  /// locale is in scope.
  final int priceMinor;

  /// The struck-through original, when the product is discounted.
  final int? compareAtPriceMinor;

  final bool inStock;
  final String? imageUrl;
  final ProductBadge badge;
  final LocalizedText? description;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final String? categoryId;
  final List<String> tags;

  /// Drives the home page's curated carousel. Absent from the card view,
  /// which never needs it, so it defaults to false rather than being null.
  final bool isFeatured;

  /// Whether the product is listed. Null on the public views, which only
  /// ever return listed products, so its absence is not "inactive".
  final bool? isActive;

  bool get isDiscounted {
    final was = compareAtPriceMinor;
    return was != null && was > priceMinor;
  }
}
