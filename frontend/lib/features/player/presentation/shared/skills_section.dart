import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../videos/application/my_videos_controller.dart';
import '../../../videos/application/public_videos_provider.dart';
import '../../../videos/application/skill_categories_provider.dart';
import '../../../videos/domain/entities/skill_category.dart';
import '../../../videos/domain/entities/video.dart';
import '../../../videos/presentation/shared/skill_category_tabs.dart';
import '../../../videos/presentation/shared/video_card.dart';
import '../../../videos/presentation/shared/video_card_skeleton.dart';
import '../../../videos/presentation/shared/video_comments_sheet.dart';
import '../../../videos/presentation/shared/video_like_button.dart';
import '../../../videos/presentation/shared/video_upload_sheet.dart';

const _skillsGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 260,
  mainAxisSpacing: AppSpacing.md,
  crossAxisSpacing: AppSpacing.md,
  childAspectRatio: 0.85,
);

/// Skills videos — a natural sibling of [MediaSection]/the Gallery card:
/// same title/spacing chrome, but backed by the dedicated `videos` feature
/// instead of `PlayerProfile.media`. [isOwner] switches between the
/// manage-my-videos view (upload, visibility toggle, delete) and the
/// read-only public view (like, comment).
class SkillsSection extends ConsumerStatefulWidget {
  const SkillsSection({
    super.key,
    required this.isOwner,
    required this.playerId,
    required this.sport,
    this.showHeading = true,
  });

  final bool isOwner;
  final String playerId;
  final String sport;

  /// Whether to render the "Skills" heading text itself — set to `false`
  /// when the caller already supplies its own title chrome (e.g.
  /// [ProfileSectionCard] in the trailing sections list). The "Add video"
  /// action stays visible either way.
  final bool showHeading;

  @override
  ConsumerState<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends ConsumerState<SkillsSection> {
  String _selectedCategoryId = kAllSkillCategoryId;

  void _onCategorySelected(String id) {
    setState(() => _selectedCategoryId = id);
    if (widget.isOwner) {
      ref.read(myVideosControllerProvider.notifier).setCategory(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(skillCategoriesProvider(widget.sport));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: widget.showHeading
                  ? Text(l10n.skillsSectionTitle, style: Theme.of(context).textTheme.titleMedium)
                  : const SizedBox.shrink(),
            ),
            if (widget.isOwner)
              FilledButton.icon(
                onPressed: () => VideoUploadSheet.show(context, sport: widget.sport),
                icon: const Icon(Icons.add),
                label: Text(l10n.addVideoLabel),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        categoriesAsync.when(
          data: (categories) => SkillCategoryTabs(
            categories: categories,
            selectedId: _selectedCategoryId,
            onSelected: _onCategorySelected,
          ),
          loading: () => const SizedBox(height: 40, child: LinearProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.lg),
        widget.isOwner
            ? const _OwnerGrid()
            : _PublicGrid(
                query: (playerId: widget.playerId, category: _selectedCategoryId),
              ),
      ],
    );
  }
}

class _OwnerGrid extends ConsumerWidget {
  const _OwnerGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(myVideosControllerProvider);

    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) return const _EmptyState();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: _skillsGridDelegate,
          itemCount: videos.length,
          itemBuilder: (context, index) =>
              _OwnerVideoCard(key: ValueKey(videos[index].id), video: videos[index]),
        );
      },
      loading: () => const VideoGridSkeleton(gridDelegate: _skillsGridDelegate, itemCount: 3),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: ErrorState(
          onRetry: () => ref.read(myVideosControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

class _OwnerVideoCard extends ConsumerWidget {
  const _OwnerVideoCard({super.key, required this.video});

  final Video video;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.videoDeleteTitle),
        content: Text(l10n.videoDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteLabel, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(myVideosControllerProvider.notifier).delete(video.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VideoCard(
      video: video,
      commentCount: video.commentCount,
      onCommentTap: () => showVideoCommentsSheet(
        context,
        videoId: video.id,
        onCommentCountChanged: (delta) => ref
            .read(myVideosControllerProvider.notifier)
            .incrementCommentCount(video.id, delta),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.white),
        onSelected: (value) async {
          if (value == 'visibility') {
            final next = video.visibility == VideoVisibility.public
                ? VideoVisibility.private
                : VideoVisibility.public;
            try {
              await ref
                  .read(myVideosControllerProvider.notifier)
                  .updateVisibility(video.id, next);
            } on AppException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
              }
            }
          } else if (value == 'delete') {
            await _confirmDelete(context, ref);
          }
        },
        itemBuilder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return [
            PopupMenuItem(
              value: 'visibility',
              child: Text(
                video.visibility == VideoVisibility.public
                    ? l10n.videoMakePrivate
                    : l10n.videoMakePublic,
              ),
            ),
            PopupMenuItem(value: 'delete', child: Text(l10n.deleteLabel)),
          ];
        },
      ),
    );
  }
}

class _PublicGrid extends ConsumerWidget {
  const _PublicGrid({required this.query});

  final PublicVideosQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(publicVideosProvider(query));

    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) return const _EmptyState();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: _skillsGridDelegate,
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return VideoCard(
              key: ValueKey(video.id),
              video: video,
              likeButton: VideoLikeButton(
                video: video,
                onToggle: () => ref.read(publicVideosProvider(query).notifier).toggleLike(video.id),
              ),
              onCommentTap: () => showVideoCommentsSheet(context, videoId: video.id),
            );
          },
        );
      },
      loading: () => const VideoGridSkeleton(gridDelegate: _skillsGridDelegate, itemCount: 3),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: ErrorState(onRetry: () => ref.invalidate(publicVideosProvider(query))),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyStateIllustration(variant: EmptyStateVariant.noVideos),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.videosEmptyState,
              style: const TextStyle(color: AppColors.greyLight),
            ),
          ],
        ),
      ),
    );
  }
}
