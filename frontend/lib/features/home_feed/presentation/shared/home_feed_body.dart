import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/feed_item.dart';
import 'create_post_sheet.dart';
import 'feed_layout.dart';
import 'home_feed_slivers.dart';

/// The Home tab's feed as a standalone screen — an unfiltered,
/// infinite-scroll feed of Video + Photo posts in the player's own sport.
///
/// This is now only the *chrome* around [HomeFeedSliver]: the scroll view,
/// the column cap and the composer FAB. A screen that already has its own
/// scroll view (the Club's Home, which shows identity, roster metrics and
/// the feed as one page) embeds [HomeFeedSliver] directly instead, so
/// there's never a scroll view inside a scroll view.
class HomeFeedBody extends StatelessWidget {
  const HomeFeedBody({
    super.key,
    this.maxWidth = FeedLayout.columnMaxWidth,
    this.role = UserRole.player,
    this.showComposerFab = true,
    this.kindFilter,
    this.onCreatePost,
    this.listPadding = const EdgeInsets.symmetric(vertical: AppSpacing.lg),
  });

  /// Caps the feed column so cards stay a readable width (and keep
  /// scaling with browser zoom — see [FeedLayout]) on wide viewports.
  /// Pass `double.infinity` when the embedding screen already applies its
  /// own cap, so the feed fills it instead of centering a narrower column
  /// inside one.
  final double maxWidth;

  /// Which role's composer [CreatePostSheet.show] opens for — a Club
  /// embedding this feed posts as a Club, not a Player.
  final UserRole role;

  /// Hide the floating "new post" button when the embedding screen already
  /// has its own compose entry point (e.g. the Club dashboard header).
  final bool showComposerFab;

  /// Restricts the rendered list to one content type — see
  /// [HomeFeedSliver.kindFilter].
  final FeedItemKind? kindFilter;

  /// Shown as a CTA under the empty state when the feed is genuinely empty.
  final VoidCallback? onCreatePost;

  /// Gutters around the cards. Vertical-only by default: at the column cap
  /// the cards are meant to run edge to edge, the way the composer above
  /// them does. Mobile passes horizontal gutters too, since there the
  /// column *is* the screen.
  final EdgeInsetsGeometry listPadding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: showComposerFab
          ? FloatingActionButton(
              tooltip: l10n.homeFeedNewPostTooltip,
              onPressed: () => CreatePostSheet.show(context, role: role),
              child: const Icon(Icons.add_a_photo_outlined),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: FeedRefreshIndicator(
            child: CustomScrollView(
              // Keeps pull-to-refresh available even when the loaded feed
              // is shorter than the viewport.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                HomeFeedSliver(
                  kindFilter: kindFilter,
                  onCreatePost: onCreatePost,
                  padding: listPadding,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
