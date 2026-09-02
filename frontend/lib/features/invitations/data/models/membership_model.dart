import '../../domain/entities/membership.dart';
import 'invitation_model.dart'
    show dateFromJson, invitationClubFromJson, invitationPlayerFromJson;

extension PlayerClubMembershipModel on PlayerClubMembership {
  /// `{ membership: null }` for a player with no club — the endpoint
  /// answers 200 with an empty membership rather than 404, so this returns
  /// `null` rather than throwing.
  static PlayerClubMembership? fromEnvelope(Map<String, dynamic> json) {
    final membership = json['membership'] as Map<String, dynamic>?;
    if (membership == null) return null;
    final club = invitationClubFromJson(membership['club'] as Map<String, dynamic>?);
    // A membership whose club profile has been deleted has nothing to
    // render; treated as "no club" rather than as a half-drawn card.
    if (club == null) return null;
    return PlayerClubMembership(
      id: membership['id'] as String,
      club: club,
      joinedAt: dateFromJson(membership['joinedAt']),
    );
  }
}

extension ClubMembersPageModel on ClubMembersPage {
  static ClubMembersPage fromJson(Map<String, dynamic> json) {
    final items = <ClubMember>[
      for (final entry in json['items'] as List<dynamic>? ?? const [])
        if (invitationPlayerFromJson(entry as Map<String, dynamic>)
            case final player?)
          ClubMember(
            player: player,
            joinedAt: dateFromJson(entry['joinedAt']),
          ),
    ];
    return ClubMembersPage(
      items: items,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? items.length,
      total: json['total'] as int? ?? items.length,
    );
  }
}
