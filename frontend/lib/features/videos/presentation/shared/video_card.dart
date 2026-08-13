import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/video_author.dart';
import 'video_player_screen.dart';

/// A single Skills video tile — thumbnail with a play-icon overlay, a
/// category chip, and (optionally) an author row for the Community feed.
/// Tapping the thumbnail opens a full-screen player; [trailing] lets an
/// owner-only overflow menu (visibility/delete) hang off the corner
/// without this widget knowing anything about ownership.
class VideoCard extends StatefulWidget {
  const VideoCard({
    super.key,
    required this.video,
    this.showAuthor = false,
    this.likeButton,
    this.commentCount,
    this.onCommentTap,
    this.trailing,
  });

  final Video video;
  final bool showAuthor;
  final Widget? likeButton;
  final int? commentCount;
  final VoidCallback? onCommentTap;
  final Widget? trailing;

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _hovered = false;

  void _openPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(videoUrl: widget.video.secureUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final showAuthor = widget.showAuthor;
    final likeButton = widget.likeButton;
    final commentCount = widget.commentCount;
    final onCommentTap = widget.onCommentTap;
    final trailing = widget.trailing;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final hovered = _hovered && !reduceMotion;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.enter,
        transform: Matrix4.identity()
          ..scaleByDouble(hovered ? 1.02 : 1.0, hovered ? 1.02 : 1.0, 1.0, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.profileSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hovered
                ? AppColors.profileAccent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: GestureDetector(
                    onTap: () => _openPlayer(context),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (video.thumbnailUrl != null)
                          Image.network(
                            video.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const ColoredBox(color: AppColors.profileBg),
                          )
                        else
                          const ColoredBox(color: AppColors.profileBg),
                        const ColoredBox(color: Colors.black26),
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: AppColors.white,
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: _CategoryChip(label: video.category),
                ),
                if (trailing != null)
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: trailing,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                10,
                AppSpacing.md,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showAuthor && video.author != null) ...[
                    _AuthorRow(author: video.author!),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Row(
                    children: [
                      ?likeButton,
                      const SizedBox(width: AppSpacing.xs),
                      InkWell(
                        onTap: onCommentTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.mode_comment_outlined,
                                size: 18,
                                color: AppColors.greyLight,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${commentCount ?? video.commentCount}',
                                style: AppTextStyles.statNumber.copyWith(
                                  color: AppColors.greyLight,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.eyebrow.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.author});

  final VideoAuthor author;

  @override
  Widget build(BuildContext context) {
    final name = author.fullName;
    final photoUrl = author.profilePhotoUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.profileBg,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? const Icon(Icons.person, size: 14, color: AppColors.greyLight)
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            name.isEmpty ? 'Player' : name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.profileText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
