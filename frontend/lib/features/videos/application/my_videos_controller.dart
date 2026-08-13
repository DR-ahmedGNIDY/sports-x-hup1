import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../community/application/community_feed_controller.dart';
import '../data/repositories/video_repository_impl.dart';
import '../domain/entities/skill_category.dart';
import '../domain/entities/video.dart';

/// Owns the signed-in Player's own Skills videos (all visibilities) for
/// whichever category tab is currently selected. `null` category means
/// "All". Mirrors [PlayerProfileController]'s pattern of replacing state
/// with whatever the server just returned rather than reconciling partial
/// local edits.
class MyVideosController extends AsyncNotifier<List<Video>> {
  String? _category;

  String? get category => _category;

  @override
  Future<List<Video>> build() {
    return ref.read(videoRepositoryProvider).listMine(category: _category);
  }

  // The Community feed is a separate, non-autoDispose provider that only
  // refetches when its filters change — without this, a video
  // uploaded/made public/deleted here would leave Community showing a
  // stale list (missing the new video, or still showing a deleted one)
  // until the user manually changed a filter chip.
  void _invalidateCommunityFeed() =>
      ref.invalidate(communityFeedControllerProvider);

  Future<void> setCategory(String? category) async {
    if (category == kAllSkillCategoryId) category = null;
    _category = category;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(videoRepositoryProvider).listMine(category: _category),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(videoRepositoryProvider).listMine(category: _category),
    );
  }

  Future<void> upload({
    required List<int> bytes,
    required String filename,
    required String category,
    required VideoVisibility visibility,
    String? title,
  }) async {
    await ref
        .read(videoRepositoryProvider)
        .uploadVideo(
          bytes: bytes,
          filename: filename,
          category: category,
          visibility: visibility,
          title: title,
        );
    await refresh();
    _invalidateCommunityFeed();
  }

  Future<void> updateVisibility(String videoId, VideoVisibility visibility) async {
    final updated = await ref
        .read(videoRepositoryProvider)
        .updateVisibility(videoId, visibility);
    final current = state.value ?? const [];
    state = AsyncData([
      for (final video in current)
        if (video.id == updated.id) updated else video,
    ]);
    _invalidateCommunityFeed();
  }

  Future<void> updateTitle(String videoId, String? title) async {
    final updated = await ref.read(videoRepositoryProvider).updateTitle(videoId, title);
    final current = state.value ?? const [];
    state = AsyncData([
      for (final video in current)
        if (video.id == updated.id) updated else video,
    ]);
    _invalidateCommunityFeed();
  }

  Future<void> delete(String videoId) async {
    await ref.read(videoRepositoryProvider).deleteVideo(videoId);
    final current = state.value ?? const [];
    state = AsyncData(current.where((v) => v.id != videoId).toList());
    _invalidateCommunityFeed();
  }

  Future<void> toggleLike(String videoId) async {
    final current = state.value ?? const [];
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

  Future<void> incrementCommentCount(String videoId, int delta) async {
    final current = state.value ?? const [];
    state = AsyncData([
      for (final v in current)
        if (v.id == videoId) v.copyWith(commentCount: v.commentCount + delta) else v,
    ]);
  }
}

final myVideosControllerProvider = AsyncNotifierProvider<MyVideosController, List<Video>>(
  MyVideosController.new,
);
