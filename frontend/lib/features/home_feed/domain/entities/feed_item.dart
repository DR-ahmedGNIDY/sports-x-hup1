import 'feed_author.dart';

/// One Home feed item — a Video or a Photo post, unified into one shape
/// (see backend posts.mapper) so the feed renders one card component
/// instead of branching lists per media type.
enum FeedItemKind {
  video,
  photo;

  /// Also the URL segment each kind's like/comment endpoints live under
  /// (`/videos/:id/...` vs `/posts/:id/...`) — see FeedRemoteDataSource.
  String get wireValue => this == FeedItemKind.video ? 'VIDEO' : 'PHOTO';

  static FeedItemKind fromWire(String value) =>
      value == 'VIDEO' ? FeedItemKind.video : FeedItemKind.photo;
}

class FeedItem {
  const FeedItem({
    required this.kind,
    required this.id,
    required this.secureUrl,
    this.thumbnailUrl,
    this.caption,
    required this.sport,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.isLikedByMe = false,
    this.author,
    this.isHidden = false,
    this.canDelete = false,
    this.canModerate = false,
  });

  final FeedItemKind kind;
  final String id;
  final String secureUrl;
  final String? thumbnailUrl;
  final String? caption;
  final String sport;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  // The feed endpoint never tells you whether you've already liked an item
  // (same simplification as the Community feed's Video items) — this only
  // reflects a like/unlike done in this session, starting false always.
  final bool isLikedByMe;
  final FeedAuthor? author;

  /// Hidden from the public feed by a moderator. Only a moderator ever
  /// receives such an item at all, and they receive it flagged so the card
  /// can mark it and offer to put it back.
  final bool isHidden;

  /// Whether this viewer may delete the item — true for the author's own
  /// posts and for a moderator on anyone's. Decided by the server, not
  /// re-derived here.
  final bool canDelete;

  /// Whether this viewer may hide/unhide the item. Moderators only.
  final bool canModerate;

  FeedItem copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLikedByMe,
    bool? isHidden,
  }) {
    return FeedItem(
      kind: kind,
      id: id,
      secureUrl: secureUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      sport: sport,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      author: author,
      isHidden: isHidden ?? this.isHidden,
      canDelete: canDelete,
      canModerate: canModerate,
    );
  }
}
