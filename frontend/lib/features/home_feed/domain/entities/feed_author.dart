/// The poster of a Home feed item — a Player or a Club, unified into one
/// shape (see backend posts.mapper's `FeedAuthorView`) so a [FeedItemCard]
/// doesn't have to branch on who posted, only on [FeedItem.kind] for how
/// to render the media.
class FeedAuthor {
  const FeedAuthor({
    required this.role,
    this.playerId,
    this.clubId,
    required this.displayName,
    this.profilePhotoUrl,
    this.country,
  });

  /// 'PLAYER' or 'CLUB'.
  final String role;
  final String? playerId;
  final String? clubId;
  final String displayName;
  final String? profilePhotoUrl;
  final String? country;

  bool get isClub => role == 'CLUB';
}
