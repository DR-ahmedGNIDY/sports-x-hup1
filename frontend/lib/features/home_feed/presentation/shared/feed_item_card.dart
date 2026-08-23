import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// `intl` exports its own `TextDirection` (for Bidi) that otherwise shadows
// Flutter's — this file needs Flutter's `TextDirection.ltr` below, so only
// bring in the one intl symbol actually used here.
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../videos/presentation/shared/video_player_screen.dart';
import '../../domain/entities/feed_author.dart';
import '../../domain/entities/feed_item.dart';
import 'feed_action_button.dart';
import 'feed_layout.dart';
import 'feed_like_button.dart';
import 'feed_media.dart';

/// A [FeedItemCard]-shaped placeholder for the feed's initial loading
/// state — same card shell (author row, caption lines, media rectangle,
/// engagement + action rows) so the loading → loaded transition doesn't
/// visually jump.
class FeedItemCardSkeleton extends StatelessWidget {
  const FeedItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.profileColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < FeedLayout.compactCardWidth;
        final gutter = compact ? AppSpacing.md : AppSpacing.lg;
        final avatar = compact ? 36.0 : 42.0;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderOnSurface.withValues(alpha: 0.06)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, AppSpacing.md),
                child: Row(
                  children: [
                    SkeletonBox(
                      width: avatar,
                      height: avatar,
                      borderRadius: BorderRadius.all(Radius.circular(avatar / 2)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 140, height: 13),
                          SizedBox(height: 7),
                          SkeletonBox(width: 80, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.md),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 200, height: 12),
                  ],
                ),
              ),
              const AspectRatio(
                aspectRatio: FeedLayout.defaultMediaAspect,
                child: SkeletonBox(borderRadius: BorderRadius.zero),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter, vertical: AppSpacing.md),
                child: const Row(
                  children: [
                    SkeletonBox(width: 90, height: 14),
                    Spacer(),
                    SkeletonBox(width: 70, height: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One Home-feed post, shaped the way a social post reads: identity first
/// (avatar / author / when), then the author's own words, then the media,
/// then how the post is doing (likes + comments), then what you can do
/// about it (Like / Comment / Share).
///
/// The card is width-driven: it fills whatever its parent gives it and
/// adapts its own density at [FeedLayout.compactCardWidth], so Desktop's constrained
/// feed column and Mobile's full-bleed list share one component without
/// Mobile being "Desktop, smaller".
///
/// A Video item plays via the existing full-screen player on tap; a Photo
/// item is just the image. Nothing here invents engagement the backend
/// doesn't have: the counts are the feed's own `likeCount`/`commentCount`,
/// there is no share count (the API has no such field) and no multi-emoji
/// reaction set (a like is a like).
class FeedItemCard extends StatelessWidget {
  const FeedItemCard({
    super.key,
    required this.item,
    required this.onToggleLike,
    required this.onCommentTap,
  });

  final FeedItem item;
  final Future<void> Function() onToggleLike;
  final VoidCallback onCommentTap;

  void _openVideo(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => VideoPlayerScreen(videoUrl: item.secureUrl)));
  }

  // No public per-post page exists to link to, so — same honest approach
  // as ShareProfileButton — this copies the direct media URL (the one
  // real, working link available) instead of a fabricated share target.
  Future<void> _share(BuildContext context) async {
    final text = [
      if (item.caption != null && item.caption!.isNotEmpty) item.caption!,
      item.secureUrl,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.feedSharePostLinkCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.profileColors;
    final l10n = AppLocalizations.of(context)!;
    final caption = item.caption;
    final hasCaption = caption != null && caption.isNotEmpty;
    final hasEngagement = item.likeCount > 0 || item.commentCount > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < FeedLayout.compactCardWidth;
        final gutter = compact ? AppSpacing.md : AppSpacing.lg;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderOnSurface.withValues(alpha: 0.06)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                // Directional, not LTRB: the trailing gutter is tighter
                // than the leading one because the overflow menu carries
                // its own touch padding — and "trailing" has to follow the
                // reading direction, or that tighter gutter lands on the
                // avatar side in Arabic.
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  gutter,
                  compact ? AppSpacing.xs : AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: _AuthorRow(
                  author: item.author,
                  createdAt: item.createdAt,
                  compact: compact,
                  onCopyLink: () => _share(context),
                ),
              ),
              if (hasCaption)
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.md),
                  child: _FeedCaption(text: caption, compact: compact),
                ),
              FeedMedia(item: item, onPlayVideo: () => _openVideo(context)),
              if (hasEngagement)
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, AppSpacing.md, gutter, AppSpacing.sm),
                  child: _EngagementSummary(
                    likeCount: item.likeCount,
                    commentCount: item.commentCount,
                    onCommentTap: onCommentTap,
                    compact: compact,
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: Divider(
                  height: hasEngagement ? 1 : AppSpacing.md,
                  thickness: 1,
                  color: colors.borderOnSurface.withValues(alpha: 0.07),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter - AppSpacing.xs,
                  AppSpacing.xs,
                  gutter - AppSpacing.xs,
                  AppSpacing.xs + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FeedLikeButton(
                        item: item,
                        onToggle: onToggleLike,
                        compact: compact,
                      ),
                    ),
                    Expanded(
                      child: FeedActionButton(
                        icon: Icon(
                          Icons.mode_comment_outlined,
                          size: compact ? 18 : 19,
                          color: colors.textMuted,
                        ),
                        label: l10n.feedCommentActionLabel,
                        tooltip: l10n.feedCommentsTooltip,
                        onTap: onCommentTap,
                        compact: compact,
                      ),
                    ),
                    Expanded(
                      child: FeedActionButton(
                        icon: Icon(
                          Icons.ios_share_outlined,
                          size: compact ? 18 : 19,
                          color: colors.textMuted,
                        ),
                        label: l10n.feedSharePostLabel,
                        tooltip: l10n.feedSharePostLabel,
                        onTap: () => _share(context),
                        compact: compact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Identity block: avatar, author name, and when it was posted — plus the
/// post's overflow menu. The menu holds only actions the API actually
/// supports for a feed post (copying its media link); there is no
/// edit/delete endpoint for posts, so no edit/delete entry is offered.
class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.author,
    required this.createdAt,
    required this.compact,
    required this.onCopyLink,
  });

  final FeedAuthor? author;
  final DateTime createdAt;
  final bool compact;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = author?.displayName;
    final photoUrl = author?.profilePhotoUrl;
    final isClub = author?.isClub ?? false;
    final colors = context.profileColors;
    final radius = compact ? 18.0 : 21.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: colors.bg,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Icon(
                  isClub ? Icons.shield_outlined : Icons.person,
                  size: radius,
                  color: colors.textMuted,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (name == null || name.isEmpty) ? (isClub ? 'Club' : 'Player') : name,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: colors.text,
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('d MMM · HH:mm').format(createdAt.toLocal()),
                // Force LTR: inside an RTL (Arabic) layout, the bidi
                // algorithm otherwise reorders this date/time string into
                // nonsense ("Aug, 19:57 14" instead of "14 Aug, 19:57").
                textDirection: TextDirection.ltr,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textMuted,
                  fontSize: compact ? 11 : 12,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<void>(
          tooltip: l10n.feedPostOptionsTooltip,
          icon: Icon(Icons.more_horiz, size: 20, color: colors.textMuted),
          // Default padding, not zero: it's what gives the 20px glyph a
          // large enough hit area to actually be tappable on a phone.
          position: PopupMenuPosition.under,
          itemBuilder: (context) => [
            PopupMenuItem<void>(
              onTap: onCopyLink,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 18, color: colors.textMuted),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.feedCopyPostLinkLabel),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The post's own words. Collapsed to [_collapsedMaxLines] with a
/// "See more" toggle when it's longer than that — measured against the
/// real available width so the toggle only ever appears when the text is
/// genuinely clipped.
class _FeedCaption extends StatefulWidget {
  const _FeedCaption({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  State<_FeedCaption> createState() => _FeedCaptionState();
}

class _FeedCaptionState extends State<_FeedCaption> {
  static const int _collapsedMaxLines = 4;

  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _FeedCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recycled into a different post (ListView.builder reuses elements) —
    // don't carry the previous post's expanded state over.
    if (oldWidget.text != widget.text && _expanded) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.profileColors;
    // 1.7 line-height: Arabic glyphs sit taller than Latin ones, so the
    // default 1.5 leaves diacritics/descenders visually cramped.
    final style = AppTextStyles.body.copyWith(
      color: colors.text,
      fontSize: widget.compact ? 14 : 15,
      height: 1.7,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedMaxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : _collapsedMaxLines,
              overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
            if (overflows)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _expanded ? l10n.feedCaptionShowLessLabel : l10n.feedCaptionShowMoreLabel,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: colors.accent,
                        fontSize: widget.compact ? 13 : 13.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "How this post is doing" — likes on one side, comments on the other.
/// Only real counts: a zero count is omitted rather than shown as "0", and
/// there is no share count because the API doesn't record one.
class _EngagementSummary extends StatelessWidget {
  const _EngagementSummary({
    required this.likeCount,
    required this.commentCount,
    required this.onCommentTap,
    required this.compact,
  });

  final int likeCount;
  final int commentCount;
  final VoidCallback onCommentTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.profileColors;
    final countStyle = AppTextStyles.statNumber.copyWith(
      color: colors.textMuted,
      fontSize: compact ? 12.5 : 13,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        if (likeCount > 0)
          Semantics(
            label: l10n.feedLikesCountLabel(likeCount),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                  child: const Icon(Icons.favorite, size: 11, color: AppColors.white),
                ),
                const SizedBox(width: AppSpacing.sm - 2),
                ExcludeSemantics(child: Text('$likeCount', style: countStyle)),
              ],
            ),
          ),
        const Spacer(),
        if (commentCount > 0)
          InkWell(
            onTap: onCommentTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
              child: Text(l10n.feedCommentsCountLabel(commentCount), style: countStyle),
            ),
          ),
      ],
    );
  }
}
