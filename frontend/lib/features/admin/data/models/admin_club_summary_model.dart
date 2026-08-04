import '../../domain/entities/admin_club_summary.dart';

extension AdminClubSummaryModel on AdminClubSummary {
  static AdminClubSummary fromJson(Map<String, dynamic> json) {
    return AdminClubSummary(
      id: json['id'] as String,
      name: json['name'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
    );
  }
}
