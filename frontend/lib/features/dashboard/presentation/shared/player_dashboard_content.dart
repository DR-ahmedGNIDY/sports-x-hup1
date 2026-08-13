import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/application/player_profile_controller.dart';
import '../../../player/application/player_stats_controller.dart';
import '../../../player/domain/entities/player_stats.dart';
import '../../../player/presentation/shared/player_enum_labels.dart';
import '../../../player/presentation/shared/visibility_section.dart';

/// The Player Dashboard body — shared verbatim between Desktop and Mobile
/// shells (unlike most of this codebase's presentation layer) because its
/// content doesn't diverge by form factor: it's a column of cards that
/// reflows fine at any width. Only the surrounding chrome (sidebar vs.
/// bottom nav) differs, and that stays in dashboard_page_desktop/mobile.
class PlayerDashboardContent extends ConsumerWidget {
  const PlayerDashboardContent({super.key, this.maxWidth = 760});

  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatsControllerProvider);
    final profile = ref.watch(playerProfileControllerProvider).value;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(playerStatsControllerProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  profile != null && profile.fullName.isNotEmpty
                      ? l10n.dashboardWelcomeMessage(profile.fullName)
                      : l10n.dashboardWelcomeMessageNoName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                statsAsync.when(
                  data: (stats) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CompletionCard(stats: stats),
                      const SizedBox(height: AppSpacing.lg),
                      _StatsRow(stats: stats),
                    ],
                  ),
                  loading: () => const _StatsSkeleton(),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: ErrorState(
                      onRetry: () =>
                          ref.invalidate(playerStatsControllerProvider),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: VisibilitySection(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _QuickActionsCard(l10n: l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final progressColor = stats.isComplete
        ? AppColors.success
        : colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dashboardProfileCompletionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l10n.dashboardProfileCompletePercent(stats.completionPercent),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: progressColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stats.completionPercent / 100,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: progressColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (stats.isComplete)
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(l10n.dashboardProfileCompleteMessage)),
                ],
              )
            else ...[
              Text(
                l10n.dashboardMissingFieldsHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: stats.missingFields
                    .map(
                      (key) => ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: Text(missingFieldLabel(l10n, key)),
                        onPressed: () => context.go('/player/edit'),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: [
        _StatTile(
          icon: Icons.bookmark_outline,
          value: '${stats.savedByClubsCount}',
          label: l10n.dashboardStatSavedByClubs,
        ),
        _StatTile(
          icon: Icons.perm_media_outlined,
          value: '${stats.mediaCount}',
          label: l10n.dashboardStatMedia,
        ),
        _StatTile(
          icon: Icons.emoji_events_outlined,
          value: '${stats.achievementsCount}',
          label: l10n.dashboardStatAchievements,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.statNumber.copyWith(
                      fontSize: Theme.of(
                        context,
                      ).textTheme.titleLarge?.fontSize,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder matching [_CompletionCard] + [_StatsRow]'s shape —
/// a card-sized bar/progress-bar block above a row of stat-tile-sized
/// boxes — so the dashboard doesn't jump when the real stats arrive.
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonBox(width: 160, height: 18),
                    SkeletonBox(width: 48, height: 18),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SkeletonBox(height: 8, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: AppSpacing.lg),
                const SkeletonBox(width: double.infinity, height: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: List.generate(
            3,
            (_) => ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkeletonBox(
                        width: 24,
                        height: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(width: 28, height: 18),
                          SizedBox(height: 6),
                          SkeletonBox(width: 60, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.dashboardQuickActionsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/player/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.dashboardEditProfile),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/player/preview'),
                  icon: const Icon(Icons.badge_outlined),
                  label: Text(l10n.dashboardMyProfile),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
