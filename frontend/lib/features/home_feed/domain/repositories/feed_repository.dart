import '../../../videos/domain/entities/video.dart' show VideoLikeResult;
import '../../../videos/domain/entities/video_comment.dart';
import '../../../videos/domain/entities/video_comments_page.dart';
import '../entities/feed_item.dart';
import '../entities/feed_page.dart';

/// All methods throw [AppException] (core/errors) on failure. Like/comment
/// entities are shared with the Videos feature ([VideoLikeResult]/
/// [VideoComment]/[VideoCommentsPage]) — the wire shape is identical, so
/// there's nothing feed-specific to model for those.
abstract class FeedRepository {
  /// The unified Home feed — Videos + Photo posts merged by date, scoped
  /// to one sport, no other filter.
  Future<FeedPage> getFeed({required String sport, int page = 1});

  /// Publishes a Photo post — Player or Club. [sport] is required for a
  /// Club (no profile sport to default from); optional for a Player,
  /// whose own profile sport is used when omitted (mirrors
  /// `CreatePhotoPostDto` on the backend).
  Future<FeedItem> createPost({
    required List<int> bytes,
    required String filename,
    String? caption,
    String? sport,
  });

  Future<VideoLikeResult> like(FeedItemKind kind, String id);

  Future<VideoLikeResult> unlike(FeedItemKind kind, String id);

  Future<VideoCommentsPage> listComments(FeedItemKind kind, String id, {int page = 1});

  Future<VideoComment> addComment(FeedItemKind kind, String id, String text);

  Future<void> deleteComment(FeedItemKind kind, String id, String commentId);

  /// Deletes a post — the caller's own, or anyone's if they moderate.
  /// Final: it removes the underlying media too.
  Future<void> deleteFeedItem(FeedItemKind kind, String id);

  /// Hides a post from the public feed, or puts it back. Moderators only,
  /// and reversible — the preferred action over [deleteFeedItem].
  Future<void> setFeedItemHidden(FeedItemKind kind, String id, bool hidden);
}
