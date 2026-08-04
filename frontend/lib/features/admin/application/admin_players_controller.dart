import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/admin_repository_impl.dart';
import '../domain/entities/admin_player_summary.dart';

class AdminPlayersController extends AsyncNotifier<List<AdminPlayerSummary>> {
  @override
  Future<List<AdminPlayerSummary>> build() {
    return ref.read(adminRepositoryProvider).getPlayers();
  }

  Future<void> deletePlayer(String playerId) async {
    await ref.read(adminRepositoryProvider).deletePlayer(playerId);
    final current = state.value ?? const [];
    state = AsyncData(current.where((p) => p.id != playerId).toList());
  }
}

final adminPlayersControllerProvider =
    AsyncNotifierProvider<AdminPlayersController, List<AdminPlayerSummary>>(
      AdminPlayersController.new,
    );
