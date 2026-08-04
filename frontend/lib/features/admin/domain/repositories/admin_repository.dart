import '../entities/admin_club_summary.dart';
import '../entities/admin_player_summary.dart';
import '../entities/admin_user.dart';

/// Throws [AppException] (core/errors) on failure.
abstract class AdminRepository {
  Future<List<AdminUser>> getUsers();

  Future<void> setUserStatus(String userId, String status);

  Future<void> deleteUser(String userId);

  Future<List<AdminPlayerSummary>> getPlayers();

  Future<void> deletePlayer(String playerId);

  Future<List<AdminClubSummary>> getClubs();

  Future<void> deleteClub(String clubId);
}
