import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/admin/presentation/admin_store_categories_tab.dart';
import 'package:sport_x_hub/features/store/domain/entities/localized_text.dart';
import 'package:sport_x_hub/features/store/domain/entities/store_category.dart';

StoreCategory cat(String id, int sort, [String? parent]) => StoreCategory(
  id: id,
  name: LocalizedText(en: id),
  slug: id,
  parentId: parent,
  sortOrder: sort,
);

void main() {
  test('puts every shelf under its own department, not the first one', () {
    // The API's order: sorted by sortOrder alone, so every department's
    // shelves (0, 1, 2) land right after the first department (0).
    final flat = [
      cat('men', 0),
      cat('men-clothing', 0, 'men'),
      cat('women-clothing', 0, 'women'),
      cat('kids-clothing', 0, 'kids'),
      cat('men-shoes', 1, 'men'),
      cat('women-shoes', 1, 'women'),
      cat('kids-shoes', 1, 'kids'),
      cat('women', 10),
      cat('kids', 20),
    ];

    expect(categoryTree(flat).map((c) => c.id), [
      'men', 'men-clothing', 'men-shoes',
      'women', 'women-clothing', 'women-shoes',
      'kids', 'kids-clothing', 'kids-shoes',
    ]);
  });

  test('keeps a shelf whose department is missing, at the top level', () {
    final tree = categoryTree([cat('orphan', 0, 'gone'), cat('men', 1)]);
    expect(tree.map((c) => c.id), ['orphan', 'men']);
  });
}
