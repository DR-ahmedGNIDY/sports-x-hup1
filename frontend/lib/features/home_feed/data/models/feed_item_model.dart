import '../../domain/entities/feed_author.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/entities/feed_page.dart';

extension FeedAuthorModel on FeedAuthor {
  static FeedAuthor fromJson(Map<String, dynamic> json) {
    return FeedAuthor(
      role: json['role'] as String,
      playerId: json['playerId'] as String?,
      clubId: json['clubId'] as String?,
      displayName: json['displayName'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      country: json['country'] as String?,
    );
  }
}

extension FeedItemModel on FeedItem {
  static FeedItem fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>?;
    return FeedItem(
      kind: FeedItemKind.fromWire(json['kind'] as String),
      id: json['id'] as String,
      secureUrl: json['secureUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      caption: json['caption'] as String?,
      sport: json['sport'] as String,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      author: authorJson != null ? FeedAuthorModel.fromJson(authorJson) : null,
    );
  }
}

extension FeedPageModel on FeedPage {
  static FeedPage fromJson(Map<String, dynamic> json) {
    return FeedPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => FeedItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
    );
  }
}
