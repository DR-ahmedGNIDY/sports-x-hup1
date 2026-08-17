import 'achievement.dart';
import 'contact_details.dart';
import 'player_enums.dart';
import 'player_media.dart';
import 'profile_photo.dart';
import 'social_link.dart';

/// Owner's own profile — includes contact details and the current
/// visibility setting regardless of what that setting is.
class PlayerProfile {
  const PlayerProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.nationality,
    this.country,
    this.city,
    this.sport,
    this.position,
    this.preferredFoot,
    this.height,
    this.weight,
    this.currentStatus,
    this.currentClub,
    this.bio,
    this.contact = const ContactDetails(),
    this.visibility = ProfileVisibility.private,
    this.media = const [],
    this.profilePhoto,
    this.achievements = const [],
    this.socialLinks = const [],
    this.createdAt,
    this.completionPercent,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? country;
  final String? city;
  final String? sport;
  final String? position;
  final PreferredFoot? preferredFoot;
  final num? height;
  final num? weight;
  final String? currentStatus;
  final String? currentClub;
  final String? bio;
  final ContactDetails contact;
  final ProfileVisibility visibility;
  final List<PlayerMedia> media;
  final ProfilePhoto? profilePhoto;
  final List<Achievement> achievements;
  final List<SocialLink> socialLinks;

  /// When this profile document was created. Only meaningful for owner
  /// views (`toOwnerView` on the backend) — public/search views never
  /// populate it. Used by the Club Dashboard's "recently added players"
  /// section; `null` anywhere that view doesn't apply.
  final DateTime? createdAt;

  /// The same per-field completion check `GET /players/me/stats` computes,
  /// carried on every owner view (`toOwnerView`) so a roster row can show
  /// it without a second request. `null` anywhere that view doesn't apply
  /// (public/search views never populate it).
  final int? completionPercent;

  String get fullName => [
    firstName,
    lastName,
  ].where((part) => part != null && part.isNotEmpty).join(' ');
}
