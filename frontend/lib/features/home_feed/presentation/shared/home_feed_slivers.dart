import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/home_feed_controller.dart';
import '../../domain/entities/feed_item.dart';
import 'feed_comments_sheet.dart';
import 'feed_item_card.dart';
import 'feed_layout.dart';

/// The Home feed as a **sliver**, so the page that embeds it scrolls as
/// one surface instead of putting a second, inner scroll view inside a
/// fixed-height box.
///
/// That's not a cosmetic preference: sizing an embedded feed needs a
/// height, and a height picked from the viewport (or a magic constant) is
/// a fixed constraint that doesn't scale the way the rest of the page
/// does — the same class of bug as a feed column whose width tracked the
/// viewport. As a sliver the feed has no height of its own at all: it
/// contributes rows to the page's own scroll and stays lazy
/// (`SliverList.builder`, one card built at a time) exactly like the
/// `ListView.builder` it replaces.
class HomeFeedSliver extends ConsumerWidget {
  const HomeFeedSliver({
    super.key,
    this.kindFilter,
    this.onCreatePost,
    this.padding = EdgeInsets.zero,
  });

  /// Restricts the rendered list to one content type — a purely
  /// client-side filter over the already-loaded page (see [FeedTabs]);
  /// `null` shows everything.
  final FeedItemKind? kindFilter;

  /// Shown as a CTA under the empty state when the feed is genuinely empty
  /// (not just filtered down to nothing) — omit to fall back to plain
  /// text.
  final VoidCallback? onCreatePost;

  /// Gutters around the feed's cards. Horizontal padding here is what
  /// aligns the cards with whatever the embedding page puts above them
  /// (composer, tabs), so pass the page's own gutter.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(homeFeedControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return SliverPadding(
      padding: padding,
      sliver: feedAsync.when(
        loading: () => SliverList.builder(
          itemCount: 3,
          itemBuilder: (context, _) => const FeedItemCardSkeleton(),
        ),
        error: (error, _) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: ErrorState(onRetry: () => ref.invalidate(homeFeedControllerProvider)),
          ),
        ),
        data: (state) {
          final allItems = state.page.items;
          final items = kindFilter == null
              ? allItems
              : allItems.where((i) => i.kind == kindFilter).toList();

          if (allItems.isEmpty) {
            return SliverToBoxAdapter(
              child: FeedEmptyState(
                message: l10n.homeFeedEmptyState,
                onCreatePost: onCreatePost,
              ),
            );
          }

          // The underlying page isn't empty, but the current tab
          // (Photos/Videos) filtered every loaded item out.
          if (items.isEmpty) {
            return SliverToBoxAdapter(
              child: FeedEmptyState(message: l10n.homeFeedFilteredEmptyState, compact: true),
            );
          }

          final controller = ref.read(homeFeedControllerProvider.notifier);
          return SliverList.builder(
            itemCount: items.length + (state.page.hasNextPage ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= items.length) return const _FeedPageLoader();
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
          );
        },
      ),
    );
  }
}

/// The row at the end of the list while more pages exist — and the thing
/// that asks for the next one.
///
/// The trigger is this row being *mounted*, which a lazy sliver only does
/// once the end of the list comes within its build window. That replaces
/// the feed's old [ScrollController] (the page owns the scroll now) and
/// it's deliberately once-per-mount rather than once-per-build: a build
/// trigger re-fires on every state change, so a failing request would
/// retry itself as fast as the network allows. Mounted once, a failure
/// simply leaves the row sitting there; scrolling away and back mounts a
/// fresh one that tries again, and pull-to-refresh reloads outright.
class _FeedPageLoader extends ConsumerStatefulWidget {
  const _FeedPageLoader();

  @override
  ConsumerState<_FeedPageLoader> createState() => _FeedPageLoaderState();
}

class _FeedPageLoaderState extends ConsumerState<_FeedPageLoader> {
  @override
  void initState() {
    super.initState();
    // Never mutate provider state during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(homeFeedControllerProvider.notifier).loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

/// The feed column — an optional [header] (composer, tabs) with the feed
/// underneath it, capped at [maxWidth] and laid out as slivers so the
/// embedding page keeps a single scroll.
///
/// The cap is the point: a feed column left to take a plain fraction of
/// the viewport keeps growing in logical pixels as the browser zooms out,
/// so its post media never appears to shrink while the text around it
/// does. Capping in logical pixels makes the whole column scale with the
/// page. Header and cards share the cap, so they line up exactly.
class FeedColumnSliver extends StatelessWidget {
  const FeedColumnSliver({
    super.key,
    this.header,
    this.kindFilter,
    this.onCreatePost,
    this.maxWidth = FeedLayout.columnMaxWidth,
  });

  final Widget? header;
  final FeedItemKind? kindFilter;
  final VoidCallback? onCreatePost;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SliverConstrainedCrossAxis(
      maxExtent: maxWidth,
      sliver: SliverMainAxisGroup(
        slivers: [
          if (header != null) SliverToBoxAdapter(child: header),
          HomeFeedSliver(kindFilter: kindFilter, onCreatePost: onCreatePost),
        ],
      ),
    );
  }
}

/// Pull-to-refresh wired to the Home feed controller. Lives here so an
/// embedding page can keep pull-to-refresh over its *own* scroll view
/// without reaching into the feed's controller itself.
class FeedRefreshIndicator extends ConsumerWidget {
  const FeedRefreshIndicator({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(homeFeedControllerProvider.notifier).refresh(),
      child: child,
    );
  }
}

/// The feed's "nothing here" state, drawn as a real surface (illustration,
/// message, optional CTA) rather than a line of grey text floating in the
/// middle of the page.
class FeedEmptyState extends StatelessWidget {
  const FeedEmptyState({
    super.key,
    required this.message,
    this.onCreatePost,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onCreatePost;

  /// The "this tab is empty, the feed isn't" variant — same surface,
  /// smaller and without the illustration, since it's a filter result
  /// rather than a genuinely empty feed.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.profileColors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: compact ? AppSpacing.xl : AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderOnSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            const EmptyStateIllustration(variant: EmptyStateVariant.noVideos),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: colors.textMuted),
          ),
          if (onCreatePost != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onCreatePost,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.homeFeedCreateFirstPostCta),
            ),
          ],
        ],
      ),
    );
  }
}
