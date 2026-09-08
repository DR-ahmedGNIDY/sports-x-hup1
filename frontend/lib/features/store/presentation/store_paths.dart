/// Every path the storefront navigates to, in one place.
///
/// The store lives at `/store` inside the Sport X Hub app rather than on its
/// own origin, so none of its links can be written as bare `/cart`: that
/// would land on the app's own routes. Building them from [prefix] keeps the
/// pages ignorant of where the store is mounted, and makes moving it a
/// one-line change rather than a sweep through every widget.
abstract final class StorePaths {
  static const String prefix = '/store';

  static const String home = prefix;
  static const String shop = '$prefix/shop';
  static const String search = '$prefix/search';
  static const String cart = '$prefix/cart';
  static const String checkout = '$prefix/checkout';
  static const String track = '$prefix/track';
  static const String orders = '$prefix/orders';

  static String category(String slug) => '$prefix/c/$slug';
  static String product(String slug) => '$prefix/p/$slug';
  static String order(String orderNumber) => '$prefix/order/$orderNumber';
}
