import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/domain/entities/player_search_result.dart';
import '../data/repositories/saved_players_repository_impl.dart';

/// Owns the Club's saved-player set. Doubles as the data source for the
/// Saved Players list screen and as the save/unsave state search result
/// cards check against — one round trip on load, then local list edits on
/// every save/unsave instead of a full refetch.
class SavedPlayersController extends AsyncNotifier<List<PlayerSearchResult>> {
  @override
  Future<List<PlayerSearchResult>> build() {
    return ref.read(savedPlayersRepositoryProvider).getSavedPlayers();
  }

  bool isSaved(String playerId) =>
      state.valueOrNull?.any((player) => player.id == playerId) ?? false;

  Future<void> save(PlayerSearchResult player) async {
    await ref.read(savedPlayersRepositoryProvider).savePlayer(player.id);
    final current = state.valueOrNull ?? const [];
    state = AsyncData([player, ...current]);
  }

  Future<void> unsave(String playerId) async {
    await ref.read(savedPlayersRepositoryProvider).unsavePlayer(playerId);
    final current = state.valueOrNull ?? const [];
    state = AsyncData(current.where((player) => player.id != playerId).toList());
  }
}

final savedPlayersControllerProvider =
    AsyncNotifierProvider<SavedPlayersController, List<PlayerSearchResult>>(
      SavedPlayersController.new,
    );
