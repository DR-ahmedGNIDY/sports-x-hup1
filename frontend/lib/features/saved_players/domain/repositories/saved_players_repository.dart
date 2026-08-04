import '../../../player/domain/entities/player_search_result.dart';

/// Throws [AppException] (core/errors) on failure.
abstract class SavedPlayersRepository {
  Future<List<PlayerSearchResult>> getSavedPlayers();

  Future<void> savePlayer(String playerId);

  Future<void> unsavePlayer(String playerId);
}
