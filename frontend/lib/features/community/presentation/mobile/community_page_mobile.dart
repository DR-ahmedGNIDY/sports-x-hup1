import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../videos/domain/entities/skill_category.dart';
import '../../../videos/presentation/shared/video_card.dart';
import '../../../videos/presentation/shared/video_card_skeleton.dart';
import '../../../videos/presentation/shared/video_comments_sheet.dart';
import '../../../videos/presentation/shared/video_like_button.dart';
import '../../application/community_feed_controller.dart';
import '../shared/community_filters_bar.dart';
import '../shared/community_pagination.dart';

const _communityGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 14,
  crossAxisSpacing: 14,
  childAspectRatio: 0.78,
);

class CommunityPageMobile extends ConsumerWidget {
  const CommunityPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedControllerProvider);
    final controller = ref.read(communityFeedControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final colors = context.profileColors;

    return ColoredBox(
      color: colors.bg,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.communityNavLabel,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.md),
            CommunityFiltersBar(
              sport: controller.filters.sport,
              category: controller.filters.category ?? kAllSkillCategoryId,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: feedAsync.when(
                data: (page) => page.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EmptyStateIllustration(
                              variant: controller.filters.category != null
                                  ? EmptyStateVariant.noResults
                                  : EmptyStateVariant.noVideos,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.communityEmptyState,
                              style: TextStyle(color: colors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              l10n
                                  .communityActivityLabel(
                                    page.total,
                                    controller.filters.sport,
                                  )
                                  .toUpperCase(),
                              style: AppTextStyles.eyebrow.copyWith(
                                color: colors.accent,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: _communityGridDelegate,
                              itemCount: page.items.length,
                              itemBuilder: (context, index) {
                                final video = page.items[index];
                                return VideoCard(
                                  key: ValueKey(video.id),
                                  video: video,
                                  showAuthor: true,
                                  likeButton: VideoLikeButton(
                                    video: video,
                                    onToggle: () =>
                                        controller.toggleLike(video.id),
                                  ),
                                  onCommentTap: () => showVideoCommentsSheet(
                                    context,
                                    videoId: video.id,
                                    onCommentCountChanged: (delta) => controller
                                        .incrementCommentCount(video.id, delta),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (page.total > page.pageSize) ...[
                            const SizedBox(height: AppSpacing.sm),
                            CommunityPagination(
                              page: page,
                              controller: controller,
                            ),
                          ],
                        ],
                      ),
                loading: () =>
                    const VideoGridSkeleton(gridDelegate: _communityGridDelegate),
                error: (error, _) => ErrorState(
                  onRetry: () => ref.invalidate(communityFeedControllerProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
