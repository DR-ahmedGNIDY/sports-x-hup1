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

  FeedItem copyWith({int? likeCount, int? commentCount, bool? isLikedByMe}) {
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
    );
  }
}
