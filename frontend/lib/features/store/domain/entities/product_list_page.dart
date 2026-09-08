import 'store_product.dart';

class ProductListPage {
  const ProductListPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<StoreProduct> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasMore => page * pageSize < total;
}
