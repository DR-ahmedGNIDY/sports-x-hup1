import '../../../player/domain/entities/player_search_result.dart';

class PlayerSearchPage {
  const PlayerSearchPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<PlayerSearchResult> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasNextPage => page * pageSize < total;
}
