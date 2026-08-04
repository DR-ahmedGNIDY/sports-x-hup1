import '../../domain/entities/admin_player_summary.dart';

extension AdminPlayerSummaryModel on AdminPlayerSummary {
  static AdminPlayerSummary fromJson(Map<String, dynamic> json) {
    return AdminPlayerSummary(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      sport: json['sport'] as String?,
      position: json['position'] as String?,
      visibility: json['visibility'] as String?,
    );
  }
}
