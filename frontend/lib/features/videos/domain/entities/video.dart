import 'video_author.dart';

/// Response shape of `POST/DELETE /videos/:id/like` — just the two fields
/// that changed, not a full [Video].
class VideoLikeResult {
  const VideoLikeResult({required this.likeCount, required this.isLikedByMe});

  final int likeCount;
  final bool isLikedByMe;
}

enum VideoVisibility {
  public('PUBLIC', 'Public'),
  private('PRIVATE', 'Private');

  const VideoVisibility(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static VideoVisibility fromWire(String value) {
    return VideoVisibility.values.firstWhere((v) => v.wireValue == value);
  }
}

/// A single Skills video — the owner's view (uploaded via `/videos`) and the
/// public/community view (`/videos/player/:id`, `/videos/community`) share
/// this same shape; [author] is only populated on community feed items and
/// [isLikedByMe] only makes sense once a viewer is attached to the request.
class Video {
  const Video({
    required this.id,
    required this.playerId,
    required this.sport,
    required this.category,
    this.title,
    required this.secureUrl,
    this.thumbnailUrl,
    this.visibility = VideoVisibility.private,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.isLikedByMe = false,
    this.author,
  });

  final String id;
  final String playerId;
  final String sport;
  final String category;
  final String? title;
  final String secureUrl;
  final String? thumbnailUrl;
  final VideoVisibility visibility;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final bool isLikedByMe;
  final VideoAuthor? author;

  Video copyWith({
    String? title,
    VideoVisibility? visibility,
    int? likeCount,
    int? commentCount,
    bool? isLikedByMe,
  }) {
    return Video(
      id: id,
      playerId: playerId,
      sport: sport,
      category: category,
      title: title ?? this.title,
      secureUrl: secureUrl,
      thumbnailUrl: thumbnailUrl,
      visibility: visibility ?? this.visibility,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      author: author,
    );
  }
}
