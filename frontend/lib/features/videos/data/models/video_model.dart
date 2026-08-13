import '../../domain/entities/video.dart';
import '../../domain/entities/video_author.dart';

extension VideoAuthorModel on VideoAuthor {
  static VideoAuthor fromJson(Map<String, dynamic> json) {
    return VideoAuthor(
      playerId: json['playerId'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      country: json['country'] as String?,
    );
  }
}

extension VideoModel on Video {
  static Video fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>?;
    return Video(
      id: json['id'] as String,
      // Community/public feed items (`toFeedItemView` on the backend) never
      // carry a top-level `playerId` — only `/videos/me` and
      // `/videos/:id/visibility` do. Fall back to the nested author's id.
      playerId: (json['playerId'] as String?) ??
          (authorJson?['playerId'] as String?) ??
          '',
      sport: json['sport'] as String,
      category: json['category'] as String,
      title: json['title'] as String?,
      secureUrl: json['secureUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      visibility: json['visibility'] != null
          ? VideoVisibility.fromWire(json['visibility'] as String)
          : VideoVisibility.private,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isLikedByMe: json['isLikedByMe'] as bool? ?? false,
      author: authorJson != null ? VideoAuthorModel.fromJson(authorJson) : null,
    );
  }
}

extension VideoLikeResultModel on VideoLikeResult {
  static VideoLikeResult fromJson(Map<String, dynamic> json) {
    return VideoLikeResult(
      likeCount: (json['likeCount'] as num).toInt(),
      isLikedByMe: json['isLikedByMe'] as bool,
    );
  }
}
