import 'localized_text.dart';

/// One Egyptian governorate and what delivery there costs.
class ShippingZone {
  const ShippingZone({
    required this.id,
    required this.name,
    required this.code,
    required this.feeMinor,
    this.isActive,
    this.cities = const [],
  });

  final String id;
  final LocalizedText name;

  /// The stable identifier checkout sends back; the display name is not it.
  final String code;

  final int feeMinor;

  /// Null on the public listing, which only returns zones we deliver to.
  final bool? isActive;

  /// Empty until the merchant prices this governorate city by city.
  final List<ShippingCity> cities;
}

/// One city inside a governorate, priced on its own.
class ShippingCity {
  const ShippingCity({
    required this.code,
    required this.name,
    required this.feeMinor,
    this.isActive,
    this.sortOrder,
  });

  /// Stable within its governorate, like [ShippingZone.code].
  final String code;
  final LocalizedText name;
  final int feeMinor;

  /// Null on the public listing, which only returns cities we deliver to.
  final bool? isActive;
  final int? sortOrder;
}
