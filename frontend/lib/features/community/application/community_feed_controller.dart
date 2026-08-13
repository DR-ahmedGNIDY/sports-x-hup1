import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/application/lookup_providers.dart';
import '../../player/application/player_profile_controller.dart';
import '../../videos/data/repositories/video_repository_impl.dart';
import '../domain/entities/community_feed_page.dart';
import 'community_filters.dart';

/// Owns the current Community feed filters and the resulting page — mirrors
/// [PlayerSearchController]'s shape: a filter change always resets to page
/// 1, [loadPage] keeps the filters and moves through the existing result
/// set. Defaults [CommunityFilters.sport] to the signed-in player's own
/// sport (so a video they just uploaded shows up immediately without
/// having to tap a sport chip); falls back to the first of the sports list
/// for non-player viewers or players without a sport set yet.
class CommunityFeedController extends AsyncNotifier<CommunityFeedPage> {
  CommunityFilters? _filters;

  CommunityFilters get filters => _filters ?? const CommunityFilters(sport: 'Football');

  @override
  Future<CommunityFeedPage> build() async {
    if (_filters == null) {
      final sports = await ref.read(sportsProvider.future);
      String? mySport;
      try {
        final profile = await ref.read(playerProfileControllerProvider.future);
        mySport = profile.sport;
      } catch (_) {
        mySport = null;
      }
      final defaultSport = (mySport != null && sports.any((s) => s.name == mySport))
          ? mySport
          : sports.where((s) => s.name == 'Football').firstOrNull?.name ??
              (sports.isNotEmpty ? sports.first.name : 'Football');
      _filters = CommunityFilters(sport: defaultSport);
    }
    return ref
        .read(videoRepositoryProvider)
        .communityFeed(
          sport: _filters!.sport,
          category: communityCategoryFilter(_filters!.category),
          page: _filters!.page,
        );
  }

  Future<void> updateSport(String sport) async {
    _filters = filters.copyWith(sport: sport, clearCategory: true, page: 1);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(videoRepositoryProvider)
          .communityFeed(sport: _filters!.sport, category: null, page: 1),
    );
  }

  Future<void> updateCategory(String? category) async {
    _filters = filters.copyWith(category: category, clearCategory: category == null, page: 1);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(videoRepositoryProvider)
          .communityFeed(
            sport: _filters!.sport,
            category: communityCategoryFilter(_filters!.category),
            page: 1,
          ),
    );
  }

  Future<void> loadPage(int page) async {
    _filters = filters.copyWith(page: page);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(videoRepositoryProvider)
          .communityFeed(
            sport: _filters!.sport,
            category: communityCategoryFilter(_filters!.category),
            page: page,
          ),
    );
  }

  Future<void> toggleLike(String videoId) async {
    final current = state.value;
    if (current == null) return;
    final video = current.items.where((v) => v.id == videoId).firstOrNull;
    if (video == null) return;
    final result = video.isLikedByMe
        ? await ref.read(videoRepositoryProvider).unlike(videoId)
        : await ref.read(videoRepositoryProvider).like(videoId);
    state = AsyncData(
      CommunityFeedPage(
        items: [
          for (final v in current.items)
            if (v.id == videoId)
              v.copyWith(likeCount: result.likeCount, isLikedByMe: result.isLikedByMe)
            else
              v,
        ],
        page: current.page,
        pageSize: current.pageSize,
        total: current.total,
      ),
    );
  }

  Future<void> incrementCommentCount(String videoId, int delta) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      CommunityFeedPage(
        items: [
          for (final v in current.items)
            if (v.id == videoId) v.copyWith(commentCount: v.commentCount + delta) else v,
        ],
        page: current.page,
        pageSize: current.pageSize,
        total: current.total,
      ),
    );
  }
}

final communityFeedControllerProvider =
    AsyncNotifierProvider<CommunityFeedController, CommunityFeedPage>(
      CommunityFeedController.new,
    );
