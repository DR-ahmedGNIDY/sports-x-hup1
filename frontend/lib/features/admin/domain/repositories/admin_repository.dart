import '../entities/admin_club_summary.dart';
import '../entities/admin_player_summary.dart';
import '../entities/admin_stats.dart';
import '../entities/admin_user.dart';

/// One fixed-size page plus whether another page exists — backs the
/// "Load more" affordance on each admin list (the backend never returns an
/// unbounded collection).
typedef AdminPage<T> = ({List<T> items, bool hasMore});

/// Throws [AppException] (core/errors) on failure.
abstract class AdminRepository {
  Future<AdminPage<AdminUser>> getUsers({int page = 1});

  Future<AdminStats> getStats();

  Future<void> setUserStatus(String userId, String status);

  /// Suspends for a fixed term, or forever for
  /// [SuspensionDuration.permanent]. A fixed-term suspension lifts itself
  /// when it expires — nothing has to call [reactivateUser] for it.
  Future<void> suspendUser(
    String userId,
    SuspensionDuration duration, {
    String? reason,
  });

  Future<void> reactivateUser(String userId);

  /// Grants or revokes community-moderation rights.
  Future<void> setUserModerator(String userId, bool isModerator);

  Future<void> deleteUser(String userId);

  Future<AdminPage<AdminPlayerSummary>> getPlayers({int page = 1});

  Future<void> deletePlayer(String playerId);

  Future<AdminPage<AdminClubSummary>> getClubs({int page = 1});

  /// Grants or revokes the club's verification check mark.
  Future<void> setClubVerified(String clubId, bool verified);

  Future<void> deleteClub(String clubId);
}
