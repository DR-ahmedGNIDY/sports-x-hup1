import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/admin_repository_impl.dart';
import '../domain/entities/admin_player_summary.dart';

class AdminPlayersController extends AsyncNotifier<List<AdminPlayerSummary>> {
  int _page = 1;
  bool hasMore = false;

  @override
  Future<List<AdminPlayerSummary>> build() async {
    _page = 1;
    final result = await ref.read(adminRepositoryProvider).getPlayers(page: _page);
    hasMore = result.hasMore;
    return result.items;
  }

  Future<void> loadMore() async {
    if (!hasMore || state.isLoading) return;
    final nextPage = _page + 1;
    final result = await ref.read(adminRepositoryProvider).getPlayers(page: nextPage);
    _page = nextPage;
    hasMore = result.hasMore;
    state = AsyncData([...state.valueOrNull ?? const [], ...result.items]);
  }

  Future<void> deletePlayer(String playerId) async {
    await ref.read(adminRepositoryProvider).deletePlayer(playerId);
    final current = state.valueOrNull ?? const [];
    state = AsyncData(current.where((p) => p.id != playerId).toList());
  }
}

final adminPlayersControllerProvider =
    AsyncNotifierProvider<AdminPlayersController, List<AdminPlayerSummary>>(
      AdminPlayersController.new,
    );
