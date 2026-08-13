import '../../../community/domain/entities/community_feed_page.dart';
import '../entities/player_traits.dart';
import '../entities/skill_category.dart';
import '../entities/video.dart';
import '../entities/video_comment.dart';
import '../entities/video_comments_page.dart';

/// All methods throw [AppException] (core/errors) on failure.
abstract class VideoRepository {
  /// `GET /sports/categories?sport=` — no auth required.
  Future<List<SkillCategory>> getSkillCategories(String sport);

  Future<Video> uploadVideo({
    required List<int> bytes,
    required String filename,
    required String category,
    required VideoVisibility visibility,
    String? title,
  });

  /// Owner-only, all visibilities. `null` category means "All".
  Future<List<Video>> listMine({String? category});

  /// PUBLIC-only, no auth required. `null` category means "All".
  Future<List<Video>> listForPlayer(String playerId, {String? category});

  /// `null` means the signed-in player isn't on a sport traits are
  /// computed for (Football-only for now).
  Future<PlayerTraits?> getMyTraits();

  /// PUBLIC-videos-only view of another player's traits, no auth required.
  Future<PlayerTraits?> getPlayerTraits(String playerId);

  Future<Video> updateVisibility(String videoId, VideoVisibility visibility);

  Future<Video> updateTitle(String videoId, String? title);

  Future<void> deleteVideo(String videoId);

  Future<CommunityFeedPage> communityFeed({
    required String sport,
    String? category,
    int page = 1,
  });

  Future<VideoLikeResult> like(String videoId);

  Future<VideoLikeResult> unlike(String videoId);

  Future<VideoCommentsPage> listComments(String videoId, {int page = 1});

  Future<VideoComment> addComment(String videoId, String text);

  Future<void> deleteComment(String videoId, String commentId);
}
