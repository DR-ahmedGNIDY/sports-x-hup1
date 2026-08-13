import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/club_players_repository_impl.dart';
import '../domain/entities/club_managed_player.dart';
import '../domain/entities/club_player_credentials.dart';
import '../domain/entities/create_club_player_input.dart';

/// Owns the club's roster of directly-created player accounts. One round
/// trip on load, then local list edits on create — mirrors
/// SavedPlayersController's approach.
class ClubPlayersController extends AsyncNotifier<List<ClubManagedPlayer>> {
  @override
  Future<List<ClubManagedPlayer>> build() {
    return ref.read(clubPlayersRepositoryProvider).listPlayers();
  }

  /// Creates the player account and returns its one-time credentials —
  /// callers show these immediately (e.g. a "Send to WhatsApp" dialog)
  /// since the plaintext password can never be fetched again afterwards.
  Future<ClubPlayerCredentials> addPlayer(CreateClubPlayerInput input) async {
    final result = await ref.read(clubPlayersRepositoryProvider).createPlayer(input);
    final current = state.value ?? const [];
    state = AsyncData([result.player, ...current]);
    return result.credentials;
  }

  Future<ClubPlayerCredentials> resendCredentials(String userId) =>
      ref.read(clubPlayersRepositoryProvider).resendCredentials(userId);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(clubPlayersRepositoryProvider).listPlayers(),
    );
  }
}

final clubPlayersControllerProvider =
    AsyncNotifierProvider<ClubPlayersController, List<ClubManagedPlayer>>(
      ClubPlayersController.new,
    );
