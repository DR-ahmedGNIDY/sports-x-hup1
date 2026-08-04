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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(searchRepositoryProvider).search(_filters));
  }

  Future<void> loadPage(int page) async {
    _filters = _filters.copyWith(page: page);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(searchRepositoryProvider).search(_filters));
  }
}

final searchControllerProvider = AsyncNotifierProvider<PlayerSearchController, PlayerSearchPage>(
  PlayerSearchController.new,
);
