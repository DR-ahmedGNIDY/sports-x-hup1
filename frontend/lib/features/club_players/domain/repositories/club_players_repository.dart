import '../../../player/domain/entities/contact_details.dart';
import '../../../player/domain/entities/player_enums.dart';
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

  /// Same field set as `PlayerRepository.updateMyProfile` — the backend
  /// reuses the identical `UpdatePlayerProfileDto` for both, only the
  /// ownership check differs (this one requires the calling Club to have
  /// created [userId]).
  Future<ClubManagedPlayer> updatePlayer(
    String userId, {
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? nationality,
    String? country,
    String? city,
    String? sport,
    String? position,
    PreferredFoot? preferredFoot,
    num? height,
    num? weight,
    String? currentStatus,
    String? currentClub,
    String? bio,
    ContactDetails? contact,
  });

  /// Removes the club's ownership of [userId] only — the player's own
  /// account and profile are untouched and remain fully usable. Distinct
  /// from deleting a player's account, which this never does.
  Future<void> removePlayer(String userId);

  Future<ClubPlayerCredentials> resendCredentials(String userId);
}
