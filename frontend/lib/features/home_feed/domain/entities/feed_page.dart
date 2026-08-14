import 'feed_item.dart';

class FeedPage {
  const FeedPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<FeedItem> items;
  final int page;
  final int pageSize;
  final int total;

  /// Compares against the accumulated [items] length (not `page * pageSize`
  /// like CommunityFeedPage) — the Home feed controller appends pages onto
  /// one growing list for infinite scroll rather than swapping pages out.
  bool get hasNextPage => items.length < total;
}
