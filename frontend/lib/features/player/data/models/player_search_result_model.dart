import '../../domain/entities/player_enums.dart';
import '../../domain/entities/player_search_result.dart';

extension PlayerSearchResultModel on PlayerSearchResult {
  static PlayerSearchResult fromJson(Map<String, dynamic> json) {
    return PlayerSearchResult(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      age: json['age'] as int?,
      country: json['country'] as String?,
      sport: json['sport'] as String?,
      position: json['position'] as String?,
      preferredFoot: PreferredFoot.fromWire(json['preferredFoot'] as String?),
      height: json['height'] as num?,
      weight: json['weight'] as num?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
    );
  }
}
