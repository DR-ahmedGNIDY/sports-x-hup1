import '../../domain/entities/player_enums.dart';
import '../../domain/entities/player_stats.dart';

extension PlayerStatsModel on PlayerStats {
  static PlayerStats fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      completionPercent: json['completionPercent'] as int,
      missingFields: (json['missingFields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      visibility: ProfileVisibility.fromWire(json['visibility'] as String),
      mediaCount: json['mediaCount'] as int,
      achievementsCount: json['achievementsCount'] as int,
      savedByClubsCount: json['savedByClubsCount'] as int,
    );
  }
}
