import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_stats_controller.dart';
import '../../domain/entities/player_stats.dart';
import 'player_enum_labels.dart';
import 'player_profile_data.dart';
import 'quick_stats_grid.dart';
import 'section_card.dart';
import 'visibility_section.dart';

/// Owner-only "manage my profile" block: completion progress, activity
/// stats (saved-by-clubs/media/achievements counts), and the public/
/// private visibility toggle. Used to live on the Home tab (the old
/// Player Dashboard) — moved here because it's about the profile it now
/// sits inside, not about platform activity (that's the Home feed's job).
/// Renders nothing for a viewer who isn't the profile's owner; the caller
/// still has to check `isOwner` before placing this widget, since a
/// missing/failed stats fetch degrades to an inline retry rather than
/// hiding the whole section.
class OwnerAccountSection extends ConsumerWidget {
  const OwnerAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatsControllerProvider);
    final profileText = context.profileColors.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        statsAsync.when(
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CompletionCard(stats: stats),
              const SizedBox(height: 16),
              _StatsRow(stats: stats),
            ],
          ),
          loading: () => const _OwnerSectionSkeleton(),
          error: (error, _) => ProfileSectionCard(
            icon: Icons.error_outline,
            title: AppLocalizations.of(context)!.dashboardProfileCompletionTitle,
            child: ErrorState(onRetry: () => ref.invalidate(playerStatsControllerProvider)),
          ),
        ),
        const SizedBox(height: 16),
        ProfileSectionCard(
          icon: Icons.visibility_outlined,
          title: AppLocalizations.of(context)!.visibilityTitle,
          // VisibilitySection renders its own titleMedium/bodySmall text via
          // Theme.of(context), which is tuned for the app-wide Material
          // colorScheme — this card sits on the Player Profile's own
          // [ProfileColors] surface instead, so its default text color can
          // be wrong without this override.
          child: Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(
                context,
              ).textTheme.apply(bodyColor: profileText, displayColor: profileText),
            ),
            child: const VisibilitySection(showTitle: false),
          ),
        ),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileColors = context.profileColors;
    final progressColor = stats.isComplete ? AppColors.success : profileColors.accent;

    return ProfileSectionCard(
      icon: Icons.task_alt_outlined,
      title: l10n.dashboardProfileCompletionTitle,
      accentColor: progressColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboardProfileCompletePercent(stats.completionPercent),
                style: TextStyle(color: progressColor, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: LinearProgressIndicator(
              value: stats.completionPercent / 100,
              minHeight: 8,
              backgroundColor: profileColors.borderOnSurface.withValues(alpha: 0.08),
              color: progressColor,
            ),
          ),
          const SizedBox(height: 14),
          if (stats.isComplete)
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.dashboardProfileCompleteMessage,
                    style: TextStyle(color: profileColors.text, fontSize: 13),
                  ),
                ),
              ],
            )
          else ...[
            Text(
              l10n.dashboardMissingFieldsHint,
              style: TextStyle(color: profileColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.missingFields
                  .map(
                    (key) => ActionChip(
                      backgroundColor: profileColors.bg,
                      side: BorderSide(color: profileColors.borderOnSurface.withValues(alpha: 0.1)),
                      labelStyle: TextStyle(color: profileColors.text, fontSize: 12),
                      avatar: Icon(Icons.add, size: 14, color: profileColors.accent),
                      label: Text(missingFieldLabel(l10n, key)),
                      onPressed: () => context.go('/player/edit'),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// No card chrome here on purpose — each [QuickFact] tile already renders
/// on its own bordered surface (see [QuickStatsGrid]), same as the Quick
/// Stats row right under the hero card, so wrapping it in another
/// [ProfileSectionCard] would just double up the border/shadow.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return QuickStatsGrid(
      compact: true,
      facts: [
        QuickFact(
          icon: Icons.bookmark_outline,
          label: l10n.dashboardStatSavedByClubs,
          value: '${stats.savedByClubsCount}',
        ),
        QuickFact(
          icon: Icons.perm_media_outlined,
          label: l10n.dashboardStatMedia,
          value: '${stats.mediaCount}',
        ),
        QuickFact(
          icon: Icons.emoji_events_outlined,
          label: l10n.dashboardStatAchievements,
          value: '${stats.achievementsCount}',
        ),
      ],
    );
  }
}

/// Loading placeholder matching [_CompletionCard] + [_StatsRow]'s shape
/// so the section doesn't jump when the real stats arrive.
class _OwnerSectionSkeleton extends StatelessWidget {
  const _OwnerSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      icon: Icons.task_alt_outlined,
      title: AppLocalizations.of(context)!.dashboardProfileCompletionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(height: 8, borderRadius: BorderRadius.circular(AppRadius.xs)),
          const SizedBox(height: 14),
          const SkeletonBox(width: double.infinity, height: 14),
        ],
      ),
    );
  }
}
