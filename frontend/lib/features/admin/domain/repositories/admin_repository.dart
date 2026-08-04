import '../entities/admin_club_summary.dart';
import '../entities/admin_player_summary.dart';
import '../entities/admin_user.dart';

/// One fixed-size page plus whether another page exists — backs the
/// "Load more" affordance on each admin list (the backend never returns an
/// unbounded collection).
typedef AdminPage<T> = ({List<T> items, bool hasMore});

/// Throws [AppException] (core/errors) on failure.
abstract class AdminRepository {
  Future<AdminPage<AdminUser>> getUsers({int page = 1});

  Future<void> setUserStatus(String userId, String status);

  Future<void> deleteUser(String userId);

  Future<AdminPage<AdminPlayerSummary>> getPlayers({int page = 1});

  Future<void> deletePlayer(String playerId);

  Future<AdminPage<AdminClubSummary>> getClubs({int page = 1});

  Future<void> deleteClub(String clubId);
}
