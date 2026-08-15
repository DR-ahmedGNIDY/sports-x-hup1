import 'club_managed_player.dart';
import 'club_player_completion.dart';

/// Pure derived view over the Club's existing roster (`GET /club-players`)
/// for the Club Dashboard — no separate endpoint, no invented data. The
/// roster is already returned newest-first by the backend (sorted by the
/// ownership record's `createdAt`), so `recentPlayers` is just the head of
/// that same list.
class ClubDashboardSummary {
  const ClubDashboardSummary({
    required this.totalPlayers,
    required this.completeProfiles,
    required this.incompleteProfiles,
    required this.recentPlayers,
  });

  final int totalPlayers;
  final int completeProfiles;
  final int incompleteProfiles;
  final List<ClubManagedPlayer> recentPlayers;

  factory ClubDashboardSummary.fromPlayers(
    List<ClubManagedPlayer> players, {
    int recentLimit = 5,
  }) {
    final complete = players
        .where((p) => isClubPlayerProfileComplete(p.profile))
        .length;
    return ClubDashboardSummary(
      totalPlayers: players.length,
      completeProfiles: complete,
      incompleteProfiles: players.length - complete,
      recentPlayers: players.take(recentLimit).toList(),
    );
  }
}
