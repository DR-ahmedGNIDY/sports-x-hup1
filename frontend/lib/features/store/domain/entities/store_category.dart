import 'localized_text.dart';

class StoreCategory {
  const StoreCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive,
  });

  final String id;
  final LocalizedText name;

  /// The URL segment this category is addressed by — `/store/c/<slug>`.
  final String slug;

  /// Set for a child category (Men > Tops); null for a top-level one.
  final String? parentId;

  final String? imageUrl;
  final int sortOrder;

  /// Null on the public listing, which only returns active categories.
  final bool? isActive;
}
