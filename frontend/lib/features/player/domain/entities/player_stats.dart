import 'player_enums.dart';

/// Backs the Player Dashboard's completion card and quick-stats tiles.
/// Mirrors `GET /players/me/stats` — every field is derived server-side
/// from the profile document, nothing is computed on the client.
class PlayerStats {
  const PlayerStats({
    required this.completionPercent,
    required this.missingFields,
    required this.visibility,
    required this.mediaCount,
    required this.achievementsCount,
    required this.savedByClubsCount,
  });

  final int completionPercent;

  /// Keys into `missingFieldLabel` (dashboard shared widgets) — stable
  /// identifiers the backend contract defines, not display strings.
  final List<String> missingFields;
  final ProfileVisibility visibility;
  final int mediaCount;
  final int achievementsCount;
  final int savedByClubsCount;

  bool get isComplete => missingFields.isEmpty;
}
