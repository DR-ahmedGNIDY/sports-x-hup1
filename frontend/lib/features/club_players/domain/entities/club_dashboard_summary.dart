import 'club_managed_player.dart';

/// The Club Dashboard's roster summary — total/complete/incomplete counts
/// and the most-recently-added players. Computed server-side (`GET
/// /club-players/summary`, backed by the same `isProfileComplete` check
/// the backend already uses for a Player's own completion stats) so the
/// client never has to download the full roster just to show 3 numbers
/// and a short recent list.
class ClubDashboardSummary {
  const ClubDashboardSummary({
    required this.totalPlayers,
    required this.completeProfiles,
    required this.incompleteProfiles,
    required this.averageCompletionPercent,
    required this.topMissingFields,
    required this.recentPlayers,
  });

  final int totalPlayers;
  final int completeProfiles;
  final int incompleteProfiles;

  /// Roster-wide average of each player's own completion percentage
  /// (`GET /players/me/stats`'s check) — `null` for an empty roster.
  final int? averageCompletionPercent;

  /// The most-frequently-missing fields across the roster, keys into
  /// `missingFieldLabel` — empty when nothing is missing or roster is empty.
  final List<String> topMissingFields;
  final List<ClubManagedPlayer> recentPlayers;
}
