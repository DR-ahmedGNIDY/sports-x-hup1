import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/store_repository_impl.dart';
import '../domain/entities/product_list_page.dart';
import '../domain/entities/shipping_zone.dart';
import '../domain/entities/store_category.dart';
import '../domain/entities/store_product.dart';

/// The storefront navigation. Kept alive rather than refetched per screen —
/// it is on every page and it changes about as often as the shop's signage.
final storeCategoriesProvider = FutureProvider<List<StoreCategory>>(
  (ref) => ref.watch(storeRepositoryProvider).listCategories(),
);

final shippingZonesProvider = FutureProvider<List<ShippingZone>>(
  (ref) => ref.watch(storeRepositoryProvider).listShippingZones(),
);

/// The filters a listing screen is currently showing. A value type so
/// Riverpod can key one request per distinct combination and reuse the
/// result when the customer navigates back.
class ProductQuery {
  const ProductQuery({
    this.page = 1,
    this.search,
    this.categorySlug,
    this.size,
    this.colour,
    this.minPriceMinor,
    this.maxPriceMinor,
    this.featured,
    this.sort,
  });

  final int page;
  final String? search;
  final String? categorySlug;
  final String? size;
  final String? colour;
  final int? minPriceMinor;
  final int? maxPriceMinor;
  final bool? featured;
  final String? sort;

  ProductQuery copyWith({
    int? page,
    String? search,
    String? categorySlug,
    String? size,
    String? colour,
    int? minPriceMinor,
    int? maxPriceMinor,
    bool? featured,
    String? sort,
    bool clearFilters = false,
  }) {
    if (clearFilters) {
      return ProductQuery(search: search ?? this.search, sort: sort ?? this.sort);
    }
    return ProductQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      categorySlug: categorySlug ?? this.categorySlug,
      size: size ?? this.size,
      colour: colour ?? this.colour,
      minPriceMinor: minPriceMinor ?? this.minPriceMinor,
      maxPriceMinor: maxPriceMinor ?? this.maxPriceMinor,
      featured: featured ?? this.featured,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProductQuery &&
      other.page == page &&
      other.search == search &&
      other.categorySlug == categorySlug &&
      other.size == size &&
      other.colour == colour &&
      other.minPriceMinor == minPriceMinor &&
      other.maxPriceMinor == maxPriceMinor &&
      other.featured == featured &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(
    page,
    search,
    categorySlug,
    size,
    colour,
    minPriceMinor,
    maxPriceMinor,
    featured,
    sort,
  );
}

final productListProvider =
    FutureProvider.family<ProductListPage, ProductQuery>((ref, query) {
      return ref
          .watch(storeRepositoryProvider)
          .listProducts(
            page: query.page,
            search: query.search,
            categorySlug: query.categorySlug,
            size: query.size,
            colour: query.colour,
            minPriceMinor: query.minPriceMinor,
            maxPriceMinor: query.maxPriceMinor,
            featured: query.featured,
            sort: query.sort,
          );
    });

final productBySlugProvider = FutureProvider.family<StoreProduct, String>(
  (ref, slug) => ref.watch(storeRepositoryProvider).getProductBySlug(slug),
);
