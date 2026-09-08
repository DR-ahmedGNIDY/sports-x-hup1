import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/admin/presentation/admin_store_page.dart';
import 'package:sport_x_hub/features/store/data/models/store_models.dart';

void main() {
  // The merchant types pounds; the API speaks piastres. This pair is the
  // only place the two meet, so a mistake here is a mispriced catalogue.
  group('money conversion', () {
    test('renders piastres as pounds with two decimals', () {
      expect(minorToPounds(74000), '740.00');
      expect(minorToPounds(5500), '55.00');
      expect(minorToPounds(0), '0.00');
      expect(minorToPounds(7), '0.07');
    });

    test('parses what a merchant actually types', () {
      expect(poundsToMinor('740'), 74000);
      expect(poundsToMinor('740.00'), 74000);
      expect(poundsToMinor(' 65.50 '), 6550);
    });

    test('rounds rather than truncating', () {
      // 74.99 * 100 is 7498.999... in binary. Truncating would quietly
      // charge a piastre less on every such price.
      expect(poundsToMinor('74.99'), 7499);
      expect(poundsToMinor('0.29'), 29);
      expect(poundsToMinor('1.005'), 101);
    });

    test('round-trips every price the editor can produce', () {
      for (final minor in [0, 1, 99, 100, 5500, 74000, 119900, 999999]) {
        expect(poundsToMinor(minorToPounds(minor)), minor, reason: '$minor');
      }
    });

    test('rejects what is not a price, rather than coercing it to zero', () {
      // Returning 0 here would silently make a product free.
      expect(poundsToMinor(''), isNull);
      expect(poundsToMinor('free'), isNull);
      expect(poundsToMinor('-5'), isNull);
    });
  });

  // The admin responses are supersets of the public ones. These assert the
  // shared parser reads the extra fields rather than dropping them, which
  // is what the dashboard's stock counts and Unlisted labels depend on.
  group('admin product parsing', () {
    Map<String, dynamic> adminProduct() => {
      'id': 'p1',
      'title': {'en': 'Black Cargo Shorts', 'ar': 'شورت كارجو أسود'},
      'slug': 'black-cargo-shorts',
      'priceMinor': 74000,
      'inStock': true,
      'isActive': false,
      'isFeatured': true,
      'images': [
        {'publicId': 'sportxhub/store/products/p1/abc', 'secureUrl': 'https://img/1.jpg'},
      ],
      'variants': [
        {'id': 'v1', 'size': 'L', 'stock': 4},
        {'id': 'v2', 'size': 'XL', 'stock': 0},
      ],
    };

    test('reads the real stock count the public view withholds', () {
      final product = StoreProductModel.fromJson(adminProduct());
      expect(product.variants.first.stock, 4);
      expect(product.variants.last.stock, 0);
    });

    test('derives inStock from stock when the admin view omits it', () {
      final product = StoreProductModel.fromJson(adminProduct());
      // The admin response sends `stock` and no `inStock`, but the shared
      // widgets still need the boolean.
      expect(product.variants.first.inStock, isTrue);
      expect(product.variants.last.inStock, isFalse);
    });

    test('keeps the Cloudinary publicId, which is how images are deleted', () {
      final product = StoreProductModel.fromJson(adminProduct());
      expect(
        product.images.single.publicId,
        'sportxhub/store/products/p1/abc',
      );
      expect(product.images.single.url, 'https://img/1.jpg');
    });

    test('reads the unlisted and featured flags', () {
      final product = StoreProductModel.fromJson(adminProduct());
      expect(product.isActive, isFalse);
      expect(product.isFeatured, isTrue);
    });

    test('leaves isActive null on a public response', () {
      final public = Map<String, dynamic>.from(adminProduct())
        ..remove('isActive')
        ..remove('isFeatured');
      final product = StoreProductModel.fromJson(public);

      // Null means "not stated", not "unlisted" — the storefront only ever
      // returns listed products, so the admin row must not mislabel them.
      expect(product.isActive, isNull);
      expect(product.isFeatured, isFalse);
    });
  });
}
