import 'invitation.dart';

/// The club a player currently belongs to — the *authoritative* answer,
/// created only by accepting an invitation. Distinct from
/// `PlayerProfile.currentClub`, which is free text the player typed and
/// which nobody has agreed to.
class PlayerClubMembership {
  const PlayerClubMembership({
    required this.id,
    required this.club,
    this.joinedAt,
  });

  final String id;
  final InvitationClub club;
  final DateTime? joinedAt;
}

/// One row of a club's public roster: the same player summary an invitation
/// card renders — the backend reuses the very same mapper — plus when they
/// joined.
class ClubMember {
  const ClubMember({required this.player, this.joinedAt});

  final InvitationPlayer player;
  final DateTime? joinedAt;
}

/// A page of `GET /memberships/clubs/:clubId/players`.
///
/// The total counts only the members this page is allowed to show: the
/// backend filters the roster to public profiles and counts the same
/// filtered set, so this never reports "5 of 8" for a club with private
/// members.
class ClubMembersPage {
  const ClubMembersPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<ClubMember> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasNextPage => page * pageSize < total;

  static const empty = ClubMembersPage(items: [], page: 1, pageSize: 20, total: 0);
}
