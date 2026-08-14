import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/application/lookup_providers.dart';
import '../../player/application/player_profile_controller.dart';
import '../data/repositories/feed_repository_impl.dart';
import '../domain/entities/feed_item.dart';
import '../domain/entities/feed_page.dart';

/// [FeedPage] plus a "fetching the next page" flag — kept separate from
/// [AsyncValue.isLoading] so appending a page doesn't blank out the
/// already-rendered feed the way a full reload would.
class HomeFeedState {
  const HomeFeedState({required this.page, this.loadingMore = false});

  final FeedPage page;
  final bool loadingMore;

  HomeFeedState copyWith({FeedPage? page, bool? loadingMore}) {
    return HomeFeedState(page: page ?? this.page, loadingMore: loadingMore ?? this.loadingMore);
  }
}

/// The Home tab's feed — Videos + Photo posts merged, scoped to the
/// signed-in player's own sport, no category filter (see the Home feed
/// spec: this is the unfiltered "everything in your sport" view; the
/// Community tab keeps the filterable browse experience). Infinite
/// scroll — [loadMore] appends onto the same growing list rather than
/// swapping pages out, unlike CommunityFeedController's page-button UI.
class HomeFeedController extends AsyncNotifier<HomeFeedState> {
  String? _sport;

  @override
  Future<HomeFeedState> build() async {
    if (_sport == null) {
      final sports = await ref.read(sportsProvider.future);
      String? mySport;
      try {
        final profile = await ref.read(playerProfileControllerProvider.future);
        mySport = profile.sport;
      } catch (_) {
        mySport = null;
      }
      _sport = (mySport != null && sports.any((s) => s.name == mySport))
          ? mySport
          : sports.where((s) => s.name == 'Football').firstOrNull?.name ??
                (sports.isNotEmpty ? sports.first.name : 'Football');
    }
    final page = await ref.read(feedRepositoryProvider).getFeed(sport: _sport!, page: 1);
    return HomeFeedState(page: page);
  }

  Future<void> refresh() async {
    if (_sport == null) {
      ref.invalidateSelf();
      await future;
      return;
    }
    final page = await ref.read(feedRepositoryProvider).getFeed(sport: _sport!, page: 1);
    state = AsyncData(HomeFeedState(page: page));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.page.hasNextPage) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await ref
          .read(feedRepositoryProvider)
          .getFeed(sport: _sport!, page: current.page.page + 1);
      final merged = FeedPage(
        items: [...current.page.items, ...next.items],
        page: next.page,
        pageSize: next.pageSize,
        total: next.total,
      );
      state = AsyncData(HomeFeedState(page: merged));
    } catch (_) {
      // Keep the already-loaded items visible; the user can retry by
      // scrolling again (loadMore re-fires on the next scroll notification)
      // rather than losing the feed to a full error screen.
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// Publishes a Photo post and prepends it onto the already-loaded feed —
  /// safe to do locally (rather than a full refetch) because this
  /// controller's feed is always the caller's own sport, which is exactly
  /// what a Player's post here defaults to.
  Future<FeedItem> publish({required List<int> bytes, required String filename, String? caption}) async {
    final item = await ref
        .read(feedRepositoryProvider)
        .createPost(bytes: bytes, filename: filename, caption: caption);
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          page: FeedPage(
            items: [item, ...current.page.items],
            page: current.page.page,
            pageSize: current.page.pageSize,
            total: current.page.total + 1,
          ),
        ),
      );
    }
    return item;
  }

  void patchItem(String id, FeedItem Function(FeedItem) update) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        page: FeedPage(
          items: [
            for (final item in current.page.items)
              if (item.id == id) update(item) else item,
          ],
          page: current.page.page,
          pageSize: current.page.pageSize,
          total: current.page.total,
        ),
      ),
    );
  }

  Future<void> toggleLike(FeedItem item) async {
    final result = item.isLikedByMe
        ? await ref.read(feedRepositoryProvider).unlike(item.kind, item.id)
        : await ref.read(feedRepositoryProvider).like(item.kind, item.id);
    patchItem(
      item.id,
      (i) => i.copyWith(likeCount: result.likeCount, isLikedByMe: result.isLikedByMe),
    );
  }

  void incrementCommentCount(String id, int delta) {
    patchItem(id, (i) => i.copyWith(commentCount: i.commentCount + delta));
  }
}

final homeFeedControllerProvider = AsyncNotifierProvider<HomeFeedController, HomeFeedState>(
  HomeFeedController.new,
);
