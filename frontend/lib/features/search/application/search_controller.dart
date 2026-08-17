import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/search_repository_impl.dart';
import '../domain/entities/player_search_filters.dart';
import '../domain/entities/player_search_page.dart';

/// Owns the current filter set and the resulting page of players. A filter
/// change always resets to page 1; [loadPage] keeps the filters and moves
/// through the existing result set.
class PlayerSearchController extends AsyncNotifier<PlayerSearchPage> {
  PlayerSearchFilters _filters = const PlayerSearchFilters();

  PlayerSearchFilters get filters => _filters;

  @override
  Future<PlayerSearchPage> build() {
    return ref.read(searchRepositoryProvider).search(_filters);
  }

  Future<void> applyFilters(PlayerSearchFilters filters) async {
    _filters = filters.copyWith(page: 1);
    await _fetch();
  }

  /// Updates just the name search text, keeping every other filter as-is —
  /// used by the toolbar's search box, which is separate from the
  /// Sport/Position/etc. filter form. `null`/empty clears the search term
  /// (built directly rather than via `copyWith`, since `copyWith`'s
  /// `search ?? this.search` pattern can't express "clear this field").
  Future<void> updateSearch(String? search) async {
    final f = _filters;
    _filters = PlayerSearchFilters(
      search: (search == null || search.trim().isEmpty) ? null : search.trim(),
      country: f.country,
      minAge: f.minAge,
      maxAge: f.maxAge,
      position: f.position,
      minHeight: f.minHeight,
      maxHeight: f.maxHeight,
      weight: f.weight,
      preferredFoot: f.preferredFoot,
      sport: f.sport,
      page: 1,
    );
    await _fetch();
  }

  Future<void> loadPage(int page) async {
    _filters = _filters.copyWith(page: page);
    await _fetch();
  }

  Future<void> _fetch() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(searchRepositoryProvider).search(_filters));
  }
}

final searchControllerProvider = AsyncNotifierProvider<PlayerSearchController, PlayerSearchPage>(
  PlayerSearchController.new,
);
