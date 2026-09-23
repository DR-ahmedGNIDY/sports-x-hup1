/// The poster of a Home feed item — a Player or a Club, unified into one
/// shape (see backend posts.mapper's `FeedAuthorView`) so a [FeedItemCard]
/// doesn't have to branch on who posted, only on [FeedItem.kind] for how
/// to render the media.
class FeedAuthor {
  const FeedAuthor({
    required this.role,
    this.playerId,
    this.clubId,
    this.coachId,
    required this.displayName,
    this.profilePhotoUrl,
    this.country,
    this.isVerified = false,
  });

  /// 'PLAYER' or 'CLUB'.
  final String role;
  final String? playerId;
  final String? clubId;
  final String? coachId;
  final String displayName;
  final String? profilePhotoUrl;
  final String? country;

  /// Only ever true for a club: the admin-granted verification check mark
  /// shown next to the name.
  final bool isVerified;

  bool get isClub => role == 'CLUB';
  bool get isCoach => role == 'COACH';
}
