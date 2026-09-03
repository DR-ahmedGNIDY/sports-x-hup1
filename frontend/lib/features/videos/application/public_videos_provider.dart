import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/video_repository_impl.dart';
import '../domain/entities/skill_category.dart';
import '../domain/entities/video.dart';

/// Family key: which player's PUBLIC videos, and which category ("All" =
/// null, encoded here as [kAllSkillCategoryId] since Riverpod family keys
/// need value equality — a plain nullable field on a record works fine).
typedef PublicVideosQuery = ({String playerId, String category});

/// PUBLIC-only videos for a given player, filtered by category ("All" via
/// [kAllSkillCategoryId]). autoDispose: a scouting visit to one player's
/// profile shouldn't keep every browsed player's video list cached for the
/// rest of the session (mirrors [publicPlayerProfileProvider]).
///
/// A notifier rather than a plain [FutureProvider.family] so [toggleLike]
/// can patch the single liked/unliked item's state locally — same pattern
/// as [MyVideosController]/`CommunityFeedController` — instead of
/// invalidating and refetching the whole list on every like tap.
class PublicVideosController extends AutoDisposeFamilyAsyncNotifier<List<Video>, PublicVideosQuery> {
  @override
  Future<List<Video>> build(PublicVideosQuery arg) {
    final category = arg.category == kAllSkillCategoryId ? null : arg.category;
    return ref.read(videoRepositoryProvider).listForPlayer(arg.playerId, category: category);
  }

  Future<void> toggleLike(String videoId) async {
    final current = state.valueOrNull ?? const [];
    final video = current.where((v) => v.id == videoId).firstOrNull;
    if (video == null) return;
    final result = video.isLikedByMe
        ? await ref.read(videoRepositoryProvider).unlike(videoId)
        : await ref.read(videoRepositoryProvider).like(videoId);
    state = AsyncData([
      for (final v in current)
        if (v.id == videoId)
          v.copyWith(likeCount: result.likeCount, isLikedByMe: result.isLikedByMe)
        else
          v,
    ]);
  }
}

final publicVideosProvider = AsyncNotifierProvider.autoDispose
    .family<PublicVideosController, List<Video>, PublicVideosQuery>(
      PublicVideosController.new,
    );
