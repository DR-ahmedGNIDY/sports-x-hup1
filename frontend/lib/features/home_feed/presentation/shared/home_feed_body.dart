import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../application/home_feed_controller.dart';
import '../../domain/entities/feed_item.dart';
import 'create_post_sheet.dart';
import 'feed_comments_sheet.dart';
import 'feed_item_card.dart';

/// The Home tab's body — an unfiltered, infinite-scroll feed of Video +
/// Photo posts in the player's own sport. Shared between Desktop and
/// Mobile (only the surrounding chrome/width differs, same pattern as
/// PlayerDashboardContent used to follow).
class HomeFeedBody extends ConsumerStatefulWidget {
  const HomeFeedBody({
    super.key,
    this.maxWidth = 640,
    this.role = UserRole.player,
    this.showComposerFab = true,
    this.kindFilter,
    this.onCreatePost,
  });

  final double maxWidth;

  /// Which role's composer [CreatePostSheet.show] opens for — a Club
  /// embedding this feed (e.g. on its own Home) posts as a Club, not a
  /// Player.
  final UserRole role;

  /// Hide the floating "new post" button when the embedding screen already
  /// has its own compose entry point (e.g. the Club dashboard header).
  final bool showComposerFab;

  /// Restricts the rendered list to one content type — a purely
  /// client-side filter over the already-loaded page (see [ClubFeedTabs]);
  /// `null` shows everything, same as before this existed.
  final FeedItemKind? kindFilter;

  /// Shown as a CTA under the empty state when the feed is genuinely empty
  /// (not just filtered down to nothing) — omit to fall back to plain text,
  /// same as before this existed.
  final VoidCallback? onCreatePost;

  @override
  ConsumerState<HomeFeedBody> createState() => _HomeFeedBodyState();
}

class _HomeFeedBodyState extends ConsumerState<HomeFeedBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 400px from the bottom is far enough ahead that the next page is
    // usually ready before the user actually reaches the end of the list.
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(homeFeedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(homeFeedControllerProvider);
    final controller = ref.read(homeFeedControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.showComposerFab
          ? FloatingActionButton(
              tooltip: l10n.homeFeedNewPostTooltip,
              onPressed: () => CreatePostSheet.show(context, role: widget.role),
              child: const Icon(Icons.add_a_photo_outlined),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: feedAsync.when(
            data: (state) {
              final allItems = state.page.items;
              final items = widget.kindFilter == null
                  ? allItems
                  : allItems.where((i) => i.kind == widget.kindFilter).toList();

              if (allItems.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            const EmptyStateIllustration(
                              variant: EmptyStateVariant.noVideos,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.homeFeedEmptyState,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.greyLight,
                              ),
                            ),
                            if (widget.onCreatePost != null) ...[
                              const SizedBox(height: AppSpacing.lg),
                              FilledButton.icon(
                                onPressed: widget.onCreatePost,
                                icon: const Icon(Icons.add_photo_alternate_outlined),
                                label: Text(l10n.homeFeedCreateFirstPostCta),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // The underlying page isn't empty, but the current tab
              // (Photos/Videos) filtered every loaded item out.
              if (items.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    const SizedBox(height: 60),
                    Center(
                      child: Text(
                        l10n.homeFeedFilteredEmptyState,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.greyLight),
                      ),
                    ),
                  ],
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: items.length + (state.page.hasNextPage ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final item = items[index];
                    return FeedItemCard(
                      key: ValueKey('${item.kind.wireValue}-${item.id}'),
                      item: item,
                      onToggleLike: () => controller.toggleLike(item),
                      onCommentTap: () => showFeedCommentsSheet(
                        context,
                        kind: item.kind,
                        id: item.id,
                        onCommentCountChanged: (delta) =>
                            controller.incrementCommentCount(item.id, delta),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 3,
              itemBuilder: (context, _) => const FeedItemCardSkeleton(),
            ),
            error: (error, _) => ErrorState(
              onRetry: () => ref.invalidate(homeFeedControllerProvider),
            ),
          ),
        ),
      ),
    );
  }
}
