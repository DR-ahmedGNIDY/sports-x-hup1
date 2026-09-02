import '../../domain/entities/invitation.dart';
import '../../domain/entities/invitations_page.dart';
import '../../domain/entities/invitations_summary.dart';

extension InvitationModel on Invitation {
  static Invitation fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      type: InvitationType.fromWire(json['type'] as String),
      status: InvitationStatus.fromWire(json['status'] as String),
      direction: InvitationDirection.fromWire(json['direction'] as String),
      message: json['message'] as String?,
      club: invitationClubFromJson(json['club'] as Map<String, dynamic>?),
      player: invitationPlayerFromJson(json['player'] as Map<String, dynamic>?),
      canAccept: json['canAccept'] as bool? ?? false,
      canReject: json['canReject'] as bool? ?? false,
      canCancel: json['canCancel'] as bool? ?? false,
      createdAt: dateFromJson(json['createdAt']),
      expiresAt: dateFromJson(json['expiresAt']),
      respondedAt: dateFromJson(json['respondedAt']),
    );
  }
}

extension InvitationsPageModel on InvitationsPage {
  static InvitationsPage fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((e) => InvitationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return InvitationsPage(
      items: items,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? items.length,
      total: json['total'] as int? ?? items.length,
    );
  }
}

extension InvitationsSummaryModel on InvitationsSummary {
  static InvitationsSummary fromJson(Map<String, dynamic> json) {
    return InvitationsSummary(
      pendingReceived: json['pendingReceived'] as int? ?? 0,
      pendingSent: json['pendingSent'] as int? ?? 0,
    );
  }
}

// Shared with the membership models: the backend renders both sides of a
// membership with the very same summary mappers it uses for invitations, so
// decoding them twice would be two chances to disagree.
InvitationClub? invitationClubFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return InvitationClub(
    id: json['id'] as String,
    publicCode: json['publicCode'] as String?,
    name: json['name'] as String?,
    city: json['city'] as String?,
    country: json['country'] as String?,
    level: json['level'] as String?,
    logoUrl: json['logoUrl'] as String?,
  );
}

InvitationPlayer? invitationPlayerFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return InvitationPlayer(
    id: json['id'] as String,
    publicCode: json['publicCode'] as String?,
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
    sport: json['sport'] as String?,
    position: json['position'] as String?,
    country: json['country'] as String?,
    profilePhotoUrl: json['profilePhotoUrl'] as String?,
  );
}

// Dates arrive as ISO-8601 strings. Parsed leniently — a card that shows no
// date beats a list that fails to decode over one unexpected field.
DateTime? dateFromJson(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}
