import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// `intl` exports its own `TextDirection` (for Bidi) that otherwise shadows
// Flutter's — this file needs Flutter's `TextDirection.ltr` below, so only
// bring in the one intl symbol actually used here.
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../videos/presentation/shared/video_player_screen.dart';
import '../../domain/entities/feed_author.dart';
import '../../domain/entities/feed_item.dart';
import 'feed_like_button.dart';

/// A [FeedItemCard]-shaped placeholder for the feed's initial loading
/// state — same card shell (author row, media rectangle, action row) so
/// the loading → loaded transition doesn't visually jump.
class FeedItemCardSkeleton extends StatelessWidget {
  const FeedItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.profileSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const SkeletonBox(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(18))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 120, height: 12),
                      SizedBox(height: 6),
                      SkeletonBox(width: 70, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const AspectRatio(aspectRatio: 16 / 9, child: SkeletonBox()),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SkeletonBox(width: 90, height: 20),
          ),
        ],
      ),
    );
  }
}

/// One Home-feed post — full-width vertical card (author row, media,
/// caption, like/comment row), the "one social feed, mixed content types"
/// shape the Home spec asked for. A Video item plays inline via the
/// existing full-screen player on tap; a Photo item is just the image.
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.profileSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _AuthorRow(author: item.author, createdAt: item.createdAt),
          ),
          if (item.caption != null && item.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Text(item.caption!, style: const TextStyle(color: AppColors.profileText, fontSize: 14)),
            ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: item.kind == FeedItemKind.video
                ? GestureDetector(
                    onTap: () => _openVideo(context),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (item.thumbnailUrl != null)
                          Image.network(
                            item.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const ColoredBox(color: AppColors.profileBg),
                          )
                        else
                          const ColoredBox(color: AppColors.profileBg),
                        const ColoredBox(color: Colors.black26),
                        const Center(
                          child: Icon(Icons.play_circle_fill, color: AppColors.white, size: 48),
                        ),
                      ],
                    ),
                  )
                : Image.network(
                    item.secureUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const ColoredBox(color: AppColors.profileBg),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                FeedLikeButton(item: item, onToggle: onToggleLike),
                const SizedBox(width: AppSpacing.xs),
                InkWell(
                  onTap: onCommentTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mode_comment_outlined, size: 18, color: AppColors.greyLight),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${item.commentCount}',
                          style: AppTextStyles.statNumber.copyWith(color: AppColors.greyLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.feedSharePostLabel,
                  icon: const Icon(Icons.ios_share_outlined, size: 18, color: AppColors.greyLight),
                  onPressed: () => _share(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.author, required this.createdAt});

  final FeedAuthor? author;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final name = author?.displayName;
    final photoUrl = author?.profilePhotoUrl;
    final isClub = author?.isClub ?? false;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.profileBg,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Icon(
                  isClub ? Icons.shield_outlined : Icons.person,
                  size: 18,
                  color: AppColors.greyLight,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (name == null || name.isEmpty) ? (isClub ? 'Club' : 'Player') : name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.profileText, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                DateFormat('d MMM, HH:mm').format(createdAt.toLocal()),
                // Force LTR: inside an RTL (Arabic) layout, the bidi
                // algorithm otherwise reorders this date/time string into
                // nonsense ("Aug, 19:57 14" instead of "14 Aug, 19:57").
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: AppColors.greyLight, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
