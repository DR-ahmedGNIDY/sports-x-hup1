import 'localized_text.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled;

  static OrderStatus fromJson(String raw) => switch (raw) {
    'confirmed' => OrderStatus.confirmed,
    'shipped' => OrderStatus.shipped,
    'delivered' => OrderStatus.delivered,
    'cancelled' => OrderStatus.cancelled,
    _ => OrderStatus.pending,
  };
}

/// A line as it was when the order was placed — the title and price are the
/// server's snapshot, not a live lookup, so a receipt never reflows.
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.variantId,
    required this.title,
    required this.quantity,
    required this.unitPriceMinor,
    this.size,
    this.colour,
    this.imageUrl,
  });

  final String productId;
  final String variantId;
  final LocalizedText title;
  final int quantity;
  final int unitPriceMinor;
  final String? size;
  final String? colour;
  final String? imageUrl;

  int get lineTotalMinor => unitPriceMinor * quantity;
}

class OrderAddress {
  const OrderAddress({
    required this.fullName,
    required this.phone,
    required this.governorateCode,
    required this.governorateName,
    required this.city,
    required this.street,
    this.notes,
  });

  final String fullName;
  final String phone;
  final String governorateCode;
  final LocalizedText governorateName;
  final String city;
  final String street;
  final String? notes;
}

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.orderNumber,
    required this.email,
    required this.status,
    required this.lines,
    required this.address,
    required this.subtotalMinor,
    required this.shippingFeeMinor,
    required this.totalMinor,
    this.userId,
    this.createdAt,
  });

  final String id;

  /// What the customer quotes on the phone, and half of what retrieves a
  /// guest order — see the tracking form.
  final String orderNumber;

  final String email;
  final OrderStatus status;
  final List<OrderLine> lines;
  final OrderAddress address;
  final int subtotalMinor;
  final int shippingFeeMinor;
  final int totalMinor;

  /// Null for an order placed as a guest, which is how the confirmation
  /// screen knows to offer the tracking form rather than an order history.
  final String? userId;

  final DateTime? createdAt;

  bool get isGuestOrder => userId == null;
}
