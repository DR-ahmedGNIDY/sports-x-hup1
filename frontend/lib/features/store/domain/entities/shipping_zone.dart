import 'localized_text.dart';

/// One Egyptian governorate and what delivery there costs.
class ShippingZone {
  const ShippingZone({
    required this.id,
    required this.name,
    required this.code,
    required this.feeMinor,
    this.isActive,
  });

  final String id;
  final LocalizedText name;

  /// The stable identifier checkout sends back; the display name is not it.
  final String code;

  final int feeMinor;

  /// Null on the public listing, which only returns zones we deliver to.
  final bool? isActive;
}
