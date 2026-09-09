/// The dashboard's headline numbers, as one snapshot.
class StoreOverview {
  const StoreOverview({
    required this.ordersToday,
    required this.revenueTodayMinor,
    required this.pendingOrders,
    required this.outOfStockProducts,
    required this.lowStockProducts,
    required this.activeProducts,
  });

  final int ordersToday;

  /// Piastres, and excluding cancelled orders — money that was never
  /// collected should not make a slow day look busy.
  final int revenueTodayMinor;

  /// Orders waiting on the merchant. This is the number that means "there
  /// is work to do right now", so it is the one the card highlights.
  final int pendingOrders;

  /// Listed products where nothing at all can be bought.
  final int outOfStockProducts;

  /// Listed products with a size running low but still sellable — the
  /// reorder list, distinct from the ones already lost.
  final int lowStockProducts;

  final int activeProducts;

  static StoreOverview fromJson(Map<String, dynamic> json) => StoreOverview(
    ordersToday: json['ordersToday'] as int? ?? 0,
    revenueTodayMinor: json['revenueTodayMinor'] as int? ?? 0,
    pendingOrders: json['pendingOrders'] as int? ?? 0,
    outOfStockProducts: json['outOfStockProducts'] as int? ?? 0,
    lowStockProducts: json['lowStockProducts'] as int? ?? 0,
    activeProducts: json['activeProducts'] as int? ?? 0,
  );
}
