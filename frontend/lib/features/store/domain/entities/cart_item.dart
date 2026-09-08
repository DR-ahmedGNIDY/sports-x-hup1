import 'localized_text.dart';

/// A line in the customer's own cart, held on this device.
///
/// The cart is client-side by design: a guest has no session to hang a
/// server cart on, and the whole thing has to be re-priced at checkout
/// anyway because prices and stock move. [unitPriceMinor] here is therefore
/// the price *last seen*, shown so the customer can total up their basket —
/// the server prices the order independently and its answer is the one that
/// counts.
class CartItem {
  const CartItem({
    required this.productId,
    required this.variantId,
    required this.title,
    required this.unitPriceMinor,
    required this.quantity,
    this.variantLabel,
    this.imageUrl,
    this.slug,
  });

  final String productId;
  final String variantId;
  final LocalizedText title;
  final int unitPriceMinor;
  final int quantity;
  final String? variantLabel;
  final String? imageUrl;
  final String? slug;

  /// The variant is the identity — the same product in two sizes is two
  /// lines, and adding one twice must merge rather than duplicate.
  String get key => variantId;

  int get lineTotalMinor => unitPriceMinor * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    variantId: variantId,
    title: title,
    unitPriceMinor: unitPriceMinor,
    quantity: quantity ?? this.quantity,
    variantLabel: variantLabel,
    imageUrl: imageUrl,
    slug: slug,
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'variantId': variantId,
    'titleEn': title.en,
    'titleAr': title.ar,
    'unitPriceMinor': unitPriceMinor,
    'quantity': quantity,
    'variantLabel': variantLabel,
    'imageUrl': imageUrl,
    'slug': slug,
  };

  static CartItem fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] as String,
    variantId: json['variantId'] as String,
    title: LocalizedText(
      en: json['titleEn'] as String,
      ar: json['titleAr'] as String?,
    ),
    unitPriceMinor: json['unitPriceMinor'] as int,
    quantity: json['quantity'] as int,
    variantLabel: json['variantLabel'] as String?,
    imageUrl: json['imageUrl'] as String?,
    slug: json['slug'] as String?,
  );
}
