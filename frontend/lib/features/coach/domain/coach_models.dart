import '../../invitations/domain/entities/invitation.dart';
import '../../player/data/models/contact_details_model.dart';
import '../../player/domain/entities/achievement.dart';
import '../../player/domain/entities/contact_details.dart';
import '../../player/domain/entities/player_enums.dart';
import '../../player/domain/entities/social_link.dart';

/// What a club lets one of its coaches do on its behalf — mirrors the
/// backend's `CoachPermission`. [viewSquad] is always held.
enum CoachPermission {
  viewSquad('VIEW_SQUAD'),
  viewPlayerContacts('VIEW_PLAYER_CONTACTS'),
  manageCalendar('MANAGE_CALENDAR'),
  manageLineup('MANAGE_LINEUP'),
  invitePlayers('INVITE_PLAYERS'),
  createPlayers('CREATE_PLAYERS'),
  manageClubPlayers('MANAGE_CLUB_PLAYERS'),
  editClubProfile('EDIT_CLUB_PROFILE'),
  removeMembers('REMOVE_MEMBERS');

  const CoachPermission(this.wireValue);

  final String wireValue;

  /// Unknown values are dropped rather than thrown on, so a permission a
  /// newer server adds never breaks an older app.
  static List<CoachPermission> listFromWire(Object? raw) => [
    for (final value in (raw as List<dynamic>? ?? const []))
      for (final p in CoachPermission.values)
        if (p.wireValue == value) p,
  ];
}

String? _string(Object? v) => v is String && v.isNotEmpty ? v : null;
int? _int(Object? v) => v is num ? v.toInt() : null;
DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
List<String> _strings(Object? v) =>
    (v as List<dynamic>? ?? const []).whereType<String>().toList();

class CoachCertification {
  const CoachCertification({
    required this.id,
    required this.name,
    this.issuer,
    this.year,
  });

  final String id;
  final String name;
  final String? issuer;
  final int? year;

  factory CoachCertification.fromJson(Map<String, dynamic> json) =>
      CoachCertification(
        id: json['_id'] as String,
        name: json['name'] as String? ?? '',
        issuer: _string(json['issuer']),
        year: _int(json['year']),
      );
}

class CoachExperience {
  const CoachExperience({
    required this.id,
    required this.clubName,
    required this.role,
    required this.startYear,
    this.endYear,
    this.description,
  });

  final String id;
  final String clubName;
  final String role;
  final int startYear;

  /// Absent means "to date".
  final int? endYear;
  final String? description;

  factory CoachExperience.fromJson(Map<String, dynamic> json) =>
      CoachExperience(
        id: json['_id'] as String,
        clubName: json['clubName'] as String? ?? '',
        role: json['role'] as String? ?? '',
        startYear: _int(json['startYear']) ?? 0,
        endYear: _int(json['endYear']),
        description: _string(json['description']),
      );
}

class CoachMedia {
  const CoachMedia({
    required this.id,
    required this.type,
    required this.secureUrl,
    this.caption,
  });

  final String id;
  final PlayerMediaType type;
  final String secureUrl;
  final String? caption;

  bool get isVideo => type == PlayerMediaType.video;

  /// Cloudinary serves a video's poster at the same public id as `.jpg`.
  String get thumbnailUrl => isVideo
      ? secureUrl.replaceFirst(RegExp(r'\.[^./]+$'), '.jpg')
      : secureUrl;

  factory CoachMedia.fromJson(Map<String, dynamic> json) => CoachMedia(
    id: json['_id'] as String,
    type: json['type'] == 'VIDEO'
        ? PlayerMediaType.video
        : PlayerMediaType.photo,
    secureUrl: json['secureUrl'] as String,
    caption: _string(json['caption']),
  );
}

/// A club the coach currently works for, as shown on the CV.
class CoachCurrentClub {
  const CoachCurrentClub({
    required this.id,
    this.name,
    this.logoUrl,
    this.publicCode,
  });

  final String id;
  final String? name;
  final String? logoUrl;
  final String? publicCode;

  factory CoachCurrentClub.fromJson(Map<String, dynamic> json) =>
      CoachCurrentClub(
        id: json['id'] as String,
        name: _string(json['name']),
        logoUrl: _string(json['logoUrl']),
        publicCode: _string(json['publicCode']),
      );
}

/// The coach's CV. The owner fields ([contact], [visibility],
/// [completionPercent], [missingFields]) are only present on `GET
/// /coaches/me`; the public view leaves them at their defaults.
class CoachProfile {
  const CoachProfile({
    required this.id,
    this.publicCode,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.nationality,
    this.country,
    this.city,
    this.sport,
    this.headline,
    this.yearsOfExperience,
    this.bio,
    this.education,
    this.specialties = const [],
    this.preferredFormations = const [],
    this.languages = const [],
    this.profilePhotoUrl,
    this.media = const [],
    this.certifications = const [],
    this.experience = const [],
    this.achievements = const [],
    this.socialLinks = const [],
    this.currentClubs = const [],
    this.contact = const ContactDetails(),
    this.isPublic = true,
    this.completionPercent,
    this.missingFields = const [],
  });

  final String id;
  final String? publicCode;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? country;
  final String? city;
  final String? sport;
  final String? headline;
  final int? yearsOfExperience;
  final String? bio;
  final String? education;
  final List<String> specialties;
  final List<String> preferredFormations;
  final List<String> languages;
  final String? profilePhotoUrl;
  final List<CoachMedia> media;
  final List<CoachCertification> certifications;
  final List<CoachExperience> experience;
  final List<Achievement> achievements;
  final List<SocialLink> socialLinks;
  final List<CoachCurrentClub> currentClubs;
  final ContactDetails contact;
  final bool isPublic;
  final int? completionPercent;
  final List<String> missingFields;

  String get fullName => [
    firstName,
    lastName,
  ].where((part) => part != null && part.isNotEmpty).join(' ');

  String get location =>
      [city, country].where((v) => v != null && v.isNotEmpty).join(', ');

  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) => [
      for (final item in (json[key] as List<dynamic>? ?? const []))
        parse(item as Map<String, dynamic>),
    ];
    return CoachProfile(
      id: json['id'] as String,
      publicCode: _string(json['publicCode']),
      firstName: _string(json['firstName']),
      lastName: _string(json['lastName']),
      dateOfBirth: _date(json['dateOfBirth']),
      nationality: _string(json['nationality']),
      country: _string(json['country']),
      city: _string(json['city']),
      sport: _string(json['sport']),
      headline: _string(json['headline']),
      yearsOfExperience: _int(json['yearsOfExperience']),
      bio: _string(json['bio']),
      education: _string(json['education']),
      specialties: _strings(json['specialties']),
      preferredFormations: _strings(json['preferredFormations']),
      languages: _strings(json['languages']),
      profilePhotoUrl: _string(
        (json['profilePhoto'] as Map<String, dynamic>?)?['secureUrl'],
      ),
      media: list('media', CoachMedia.fromJson),
      certifications: list('certifications', CoachCertification.fromJson),
      experience: list('experience', CoachExperience.fromJson),
      achievements: list(
        'achievements',
        (a) => Achievement(
          id: a['_id'] as String,
          title: a['title'] as String? ?? '',
          year: _int(a['year']) ?? 0,
          description: _string(a['description']),
        ),
      ),
      socialLinks: list(
        'socialLinks',
        (l) => SocialLink(
          id: l['_id'] as String,
          platform: l['platform'] as String? ?? '',
          url: l['url'] as String? ?? '',
        ),
      ),
      currentClubs: list('currentClubs', CoachCurrentClub.fromJson),
      contact: ContactDetailsModel.fromJson(
        json['contact'] as Map<String, dynamic>?,
      ),
      isPublic: json['visibility'] != 'PRIVATE',
      completionPercent: _int(json['completionPercent']),
      missingFields: _strings(json['missingFields']),
    );
  }
}

/// A coach as a card: search results, staff lists, invitations.
class CoachSummary {
  const CoachSummary({
    required this.id,
    this.publicCode,
    this.firstName,
    this.lastName,
    this.headline,
    this.sport,
    this.country,
    this.profilePhotoUrl,
  });

  final String id;
  final String? publicCode;
  final String? firstName;
  final String? lastName;
  final String? headline;
  final String? sport;
  final String? country;
  final String? profilePhotoUrl;

  String get fullName => [
    firstName,
    lastName,
  ].where((part) => part != null && part.isNotEmpty).join(' ');

  factory CoachSummary.fromJson(Map<String, dynamic> json) => CoachSummary(
    id: json['id'] as String,
    publicCode: _string(json['publicCode']),
    firstName: _string(json['firstName']),
    lastName: _string(json['lastName']),
    headline: _string(json['headline']),
    sport: _string(json['sport']),
    country: _string(json['country']),
    profilePhotoUrl: _string(json['profilePhotoUrl']),
  );
}

InvitationClub? _club(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  return InvitationClub(
    id: json['id'] as String,
    publicCode: _string(json['publicCode']),
    name: _string(json['name']),
    city: _string(json['city']),
    country: _string(json['country']),
    level: _string(json['level']),
    logoUrl: _string(json['logoUrl']),
  );
}

/// One of the coach's clubs — also a row of the club switcher.
class CoachClubMembership {
  const CoachClubMembership({
    required this.membershipId,
    required this.club,
    required this.permissions,
    this.joinedAt,
  });

  final String membershipId;
  final InvitationClub? club;
  final List<CoachPermission> permissions;
  final DateTime? joinedAt;

  bool can(CoachPermission permission) => permissions.contains(permission);

  factory CoachClubMembership.fromJson(Map<String, dynamic> json) =>
      CoachClubMembership(
        membershipId: json['membershipId'] as String,
        club: _club(json['club']),
        permissions: CoachPermission.listFromWire(json['permissions']),
        joinedAt: _date(json['joinedAt']),
      );
}

/// One of a club's coaches, as the club manages them.
class StaffMember {
  const StaffMember({
    required this.membershipId,
    required this.coach,
    required this.permissions,
    this.joinedAt,
  });

  final String membershipId;
  final CoachSummary? coach;
  final List<CoachPermission> permissions;
  final DateTime? joinedAt;

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    membershipId: json['membershipId'] as String,
    coach: json['coach'] is Map<String, dynamic>
        ? CoachSummary.fromJson(json['coach'] as Map<String, dynamic>)
        : null,
    permissions: CoachPermission.listFromWire(json['permissions']),
    joinedAt: _date(json['joinedAt']),
  );
}

/// A club↔coach invitation. Status and direction reuse the player
/// invitation enums — the backend's state machine is the same one.
class CoachInvitation {
  const CoachInvitation({
    required this.id,
    required this.fromClub,
    required this.status,
    required this.direction,
    this.message,
    this.club,
    this.coach,
    required this.canAccept,
    required this.canReject,
    required this.canCancel,
    this.createdAt,
  });

  final String id;

  /// `true` for CLUB_TO_COACH.
  final bool fromClub;
  final InvitationStatus status;
  final InvitationDirection direction;
  final String? message;
  final InvitationClub? club;
  final CoachSummary? coach;
  final bool canAccept;
  final bool canReject;
  final bool canCancel;
  final DateTime? createdAt;

  factory CoachInvitation.fromJson(Map<String, dynamic> json) =>
      CoachInvitation(
        id: json['id'] as String,
        fromClub: json['type'] == 'CLUB_TO_COACH',
        status: InvitationStatus.fromWire(json['status'] as String),
        direction: InvitationDirection.fromWire(json['direction'] as String),
        message: _string(json['message']),
        club: _club(json['club']),
        coach: json['coach'] is Map<String, dynamic>
            ? CoachSummary.fromJson(json['coach'] as Map<String, dynamic>)
            : null,
        canAccept: json['canAccept'] == true,
        canReject: json['canReject'] == true,
        canCancel: json['canCancel'] == true,
        createdAt: _date(json['createdAt']),
      );
}
