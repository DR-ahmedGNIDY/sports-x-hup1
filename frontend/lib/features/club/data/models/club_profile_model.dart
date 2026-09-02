import '../../domain/entities/club_profile.dart';

extension ClubProfileModel on ClubProfile {
  static ClubProfile fromJson(Map<String, dynamic> json) {
    final logo = json['logo'] as Map<String, dynamic>?;
    return ClubProfile(
      id: json['id'] as String,
      publicCode: json['publicCode'] as String?,
      name: json['name'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      logoUrl: logo?['secureUrl'] as String?,
      description: json['description'] as String?,
      foundedYear: json['foundedYear'] as int?,
      level: json['level'] as String?,
    );
  }
}
