import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/player_repository_impl.dart';
import '../domain/entities/player_stats.dart';

/// Backs the Player Dashboard. Kept separate from
/// [playerProfileControllerProvider] because most dashboard visits don't
/// need the full profile payload (media/achievements/social links) — just
/// this lean summary.
class PlayerStatsController extends AsyncNotifier<PlayerStats> {
  @override
  Future<PlayerStats> build() {
    return ref.read(playerRepositoryProvider).getMyStats();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final playerStatsControllerProvider =
    AsyncNotifierProvider<PlayerStatsController, PlayerStats>(
      PlayerStatsController.new,
    );
