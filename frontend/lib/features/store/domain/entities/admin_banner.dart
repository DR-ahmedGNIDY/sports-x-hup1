import 'localized_text.dart';

/// A banner as the dashboard sees it: the two images kept apart, so the
/// merchant can be told which one is missing, and the flags the storefront
/// view has no use for.
class AdminBanner {
  const AdminBanner({
    required this.id,
    required this.sortOrder,
    required this.isActive,
    this.desktopUrl,
    this.mobileUrl,
    this.alt,
    this.linkPath,
  });

  final String id;

  /// Null until uploaded. A banner without one is never published — that is
  /// the rule this field exists to make visible.
  final String? desktopUrl;

  /// Null means the phone gets the desktop crop.
  final String? mobileUrl;

  final LocalizedText? alt;
  final String? linkPath;
  final int sortOrder;
  final bool isActive;

  /// Why a banner is not on the storefront, or null if it is.
  String? get withheldReason {
    if (desktopUrl == null) return 'No desktop image yet';
    if (!isActive) return 'Switched off';
    return null;
  }
}
