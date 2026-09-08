import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/store/data/models/store_models.dart';
import 'package:sport_x_hub/features/store/domain/entities/store_order.dart';
import 'package:sport_x_hub/features/store/domain/entities/store_product.dart';

/// The wire format is the seam between the two halves of this feature, so
/// these fixtures are copied from the shapes the backend's mappers actually
/// emit (`store.mapper.ts`) rather than invented here.
void main() {
  group('StoreProductModel', () {
    test('parses the card view, which omits variants and sends one image', () {
      final product = StoreProductModel.fromJson({
        'id': 'p1',
        'title': {'en': 'Black Cargo Shorts', 'ar': 'شورت كارجو أسود'},
        'slug': 'black-cargo-shorts',
        'priceMinor': 74000,
        'compareAtPriceMinor': 97900,
        'image': {'publicId': 'x', 'secureUrl': 'https://img/1.jpg'},
        'badge': 'new',
        'inStock': true,
      });

      expect(product.imageUrl, 'https://img/1.jpg');
      expect(product.variants, isEmpty);
      expect(product.badge, ProductBadge.isNew);
      expect(product.isDiscounted, isTrue);
    });

    test('parses the detail view, taking the first of many images', () {
      final product = StoreProductModel.fromJson({
        'id': 'p1',
        'title': {'en': 'Black Cargo Shorts'},
        'slug': 'black-cargo-shorts',
        'priceMinor': 74000,
        'inStock': true,
        'images': [
          {'publicId': 'a', 'secureUrl': 'https://img/1.jpg'},
          {'publicId': 'b', 'secureUrl': 'https://img/2.jpg'},
        ],
        'variants': [
          {'id': 'v1', 'size': 'L', 'colour': 'black', 'inStock': true},
          {'id': 'v2', 'size': 'M', 'inStock': false},
        ],
      });

      // The card view sends `image`, the detail view sends `images`. Both
      // have to yield a tile image, since the same widget renders both.
      expect(product.imageUrl, 'https://img/1.jpg');
      expect(product.images, hasLength(2));
      expect(product.variants.first.label(), 'L · black');
      expect(product.variants.last.inStock, isFalse);
    });

    test('degrades an unknown badge rather than throwing', () {
      // A newer backend adding a badge value must not break an older client
      // — a tile that cannot name its badge should still render.
      final product = StoreProductModel.fromJson({
        'id': 'p1',
        'title': {'en': 'Tee'},
        'slug': 'tee',
        'priceMinor': 1000,
        'inStock': true,
        'badge': 'clearance',
      });

      expect(product.badge, ProductBadge.none);
    });

    test('treats a missing compare-at price as no discount', () {
      final product = StoreProductModel.fromJson({
        'id': 'p1',
        'title': {'en': 'Tee'},
        'slug': 'tee',
        'priceMinor': 1000,
        'inStock': true,
      });

      expect(product.isDiscounted, isFalse);
    });

    test('parses a page envelope', () {
      final page = StoreProductModel.pageFromJson({
        'items': [
          {
            'id': 'p1',
            'title': {'en': 'Tee'},
            'slug': 'tee',
            'priceMinor': 1000,
            'inStock': true,
          },
        ],
        'page': 2,
        'pageSize': 24,
        'total': 60,
      });

      expect(page.items, hasLength(1));
      expect(page.hasMore, isTrue);
    });

    test('knows the last page has no more', () {
      final page = StoreProductModel.pageFromJson({
        'items': const [],
        'page': 3,
        'pageSize': 24,
        'total': 60,
      });

      expect(page.hasMore, isFalse);
    });
  });

  group('StoreOrderModel', () {
    final orderJson = {
      'id': 'o1',
      'orderNumber': 'ORD-000001',
      'email': 'buyer@example.com',
      'status': 'confirmed',
      'lines': [
        {
          'productId': 'p1',
          'variantId': 'v1',
          'title': {'en': 'Black Cargo Shorts', 'ar': 'شورت كارجو أسود'},
          'size': 'L',
          'colour': 'black',
          'imageUrl': 'https://img/1.jpg',
          'quantity': 2,
          'unitPriceMinor': 74000,
        },
      ],
      'address': {
        'fullName': 'Ahmed Gnidy',
        'phone': '01012345678',
        'governorateCode': 'cairo',
        'governorateName': {'en': 'Cairo', 'ar': 'القاهرة'},
        'city': 'Nasr City',
        'street': '12 Some Street',
      },
      'subtotalMinor': 148000,
      'shippingFeeMinor': 5500,
      'totalMinor': 153500,
      'createdAt': '2026-09-08T12:00:00.000Z',
    };

    test('parses a guest order and knows it is one', () {
      final order = StoreOrderModel.fromJson(orderJson);

      // No `userId` in the payload — that absence is exactly what tells the
      // confirmation screen to show the tracking instructions.
      expect(order.isGuestOrder, isTrue);
      expect(order.status, OrderStatus.confirmed);
      expect(order.lines.single.lineTotalMinor, 148000);
      expect(order.address.governorateName.resolve(true), 'القاهرة');
    });

    test('parses an order placed while signed in', () {
      final order = StoreOrderModel.fromJson({...orderJson, 'userId': 'u1'});
      expect(order.isGuestOrder, isFalse);
    });

    test('falls back to English when a line has no Arabic title', () {
      final order = StoreOrderModel.fromJson({
        ...orderJson,
        'lines': [
          {
            ...(orderJson['lines']! as List).first as Map<String, dynamic>,
            'title': {'en': 'Untranslated Tee'},
          },
        ],
      });

      // A product can go live in English and pick up its Arabic copy later,
      // so falling back is the normal case, not an error.
      expect(order.lines.single.title.resolve(true), 'Untranslated Tee');
    });

    test('survives a missing createdAt rather than throwing', () {
      final withoutDate = Map<String, dynamic>.from(orderJson)
        ..remove('createdAt');
      expect(StoreOrderModel.fromJson(withoutDate).createdAt, isNull);
    });
  });

  group('ShippingZoneModel', () {
    test('parses a governorate and its fee', () {
      final zone = ShippingZoneModel.fromJson({
        'id': 'z1',
        'name': {'en': 'Cairo', 'ar': 'القاهرة'},
        'code': 'cairo',
        'feeMinor': 5500,
      });

      expect(zone.code, 'cairo');
      expect(zone.feeMinor, 5500);
      expect(zone.name.resolve(false), 'Cairo');
    });
  });

  group('StoreCategoryModel', () {
    test('parses a child category', () {
      final category = StoreCategoryModel.fromJson({
        'id': 'c2',
        'name': {'en': 'Tops', 'ar': 'قطع علوية'},
        'slug': 'men-tops',
        'parentId': 'c1',
        'sortOrder': 3,
      });

      expect(category.parentId, 'c1');
      expect(category.imageUrl, isNull);
    });
  });
}
