/// One slide in the storefront hero.
///
/// [mobileUrl] is never null when [desktopUrl] is not: the server falls back
/// to the desktop image for a banner whose mobile crop was never uploaded,
/// so the client picks by viewport without having to know the rule.
class StoreBanner {
  const StoreBanner({
    required this.id,
    required this.desktopUrl,
    required this.mobileUrl,
    this.altEn,
    this.altAr,
    this.linkPath,
  });

  final String id;
  final String desktopUrl;
  final String mobileUrl;

  /// Read out by screen readers and shown if the image fails. A hero
  /// carries the campaign's whole message, so an undescribed one leaves
  /// the page meaningless to anyone not seeing it.
  final String? altEn;
  final String? altAr;

  /// A storefront path such as `/c/men`, relative to the store's own root.
  /// Null for a banner that is only a picture.
  final String? linkPath;

  String? alt(bool isArabic) {
    if (!isArabic) return altEn;
    final arabic = altAr;
    return arabic == null || arabic.isEmpty ? altEn : arabic;
  }

  String imageFor({required bool isDesktop}) =>
      isDesktop ? desktopUrl : mobileUrl;
}
