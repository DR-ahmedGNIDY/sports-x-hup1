import '../entities/club_managed_player.dart';
import '../entities/club_player_credentials.dart';
import '../entities/create_club_player_input.dart';

/// All methods throw [AppException] (core/errors) on failure.
abstract class ClubPlayersRepository {
  Future<List<ClubManagedPlayer>> listPlayers();

  Future<({ClubManagedPlayer player, ClubPlayerCredentials credentials})>
  createPlayer(CreateClubPlayerInput input);

  Future<ClubManagedPlayer> getPlayer(String userId);

  Future<ClubManagedPlayer> uploadPhoto(
    String userId, {
    required List<int> bytes,
    required String filename,
  });

  Future<ClubPlayerCredentials> resendCredentials(String userId);
}
