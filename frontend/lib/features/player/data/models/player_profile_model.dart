import '../../domain/entities/achievement.dart';
import '../../domain/entities/contact_details.dart';
import '../../domain/entities/player_enums.dart';
import '../../domain/entities/player_media.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/entities/social_link.dart';

extension PlayerProfileModel on PlayerProfile {
  static PlayerProfile fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      nationality: json['nationality'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      sport: json['sport'] as String?,
      position: json['position'] as String?,
      preferredFoot: PreferredFoot.fromWire(json['preferredFoot'] as String?),
      height: json['height'] as num?,
      weight: json['weight'] as num?,
      currentStatus: json['currentStatus'] as String?,
      currentClub: json['currentClub'] as String?,
      bio: json['bio'] as String?,
      contact: _contactFromJson(json['contact'] as Map<String, dynamic>?),
      visibility: json['visibility'] != null
          ? ProfileVisibility.fromWire(json['visibility'] as String)
          : ProfileVisibility.private,
      media: ((json['media'] as List<dynamic>? ?? [])
          .map((e) => _mediaFromJson(e as Map<String, dynamic>))
          .toList()),
      achievements: ((json['achievements'] as List<dynamic>? ?? [])
          .map((e) => _achievementFromJson(e as Map<String, dynamic>))
          .toList()),
      socialLinks: ((json['socialLinks'] as List<dynamic>? ?? [])
          .map((e) => _socialLinkFromJson(e as Map<String, dynamic>))
          .toList()),
    );
  }
}

ContactDetails _contactFromJson(Map<String, dynamic>? json) {
  if (json == null) return const ContactDetails();
  return ContactDetails(
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    whatsapp: json['whatsapp'] as String?,
  );
}

PlayerMedia _mediaFromJson(Map<String, dynamic> json) {
  return PlayerMedia(
    id: json['_id'] as String? ?? json['id'] as String,
    type: PlayerMediaType.fromWire(json['type'] as String),
    secureUrl: json['secureUrl'] as String,
    isProfilePhoto: json['isProfilePhoto'] as bool? ?? false,
  );
}

Achievement _achievementFromJson(Map<String, dynamic> json) {
  return Achievement(
    id: json['_id'] as String? ?? json['id'] as String,
    title: json['title'] as String,
    year: json['year'] as int,
    description: json['description'] as String?,
  );
}

SocialLink _socialLinkFromJson(Map<String, dynamic> json) {
  return SocialLink(
    id: json['_id'] as String? ?? json['id'] as String,
    platform: json['platform'] as String,
    url: json['url'] as String,
  );
}
