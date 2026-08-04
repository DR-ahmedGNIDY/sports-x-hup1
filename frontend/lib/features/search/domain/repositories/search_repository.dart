import '../entities/player_search_filters.dart';
import '../entities/player_search_page.dart';

/// Throws [AppException] (core/errors) on failure.
abstract class SearchRepository {
  Future<PlayerSearchPage> search(PlayerSearchFilters filters);
}
