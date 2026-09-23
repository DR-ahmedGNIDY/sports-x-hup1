import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/profile_colors.dart';
import '../../../core/widgets/error_state.dart';
import '../application/admin_stats_controller.dart';
import '../domain/entities/admin_stats.dart';

/// The admin dashboard's landing screen: how many players and clubs are
/// registered, plus the counts an admin acts on from the other pages
/// (suspended accounts, verified clubs, hidden posts).
///
/// Desktop only, like the rest of the admin tooling.
class AdminOverviewPage extends ConsumerWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Admin — Overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(adminStatsProvider),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: statsAsync.when(
              data: (stats) => SingleChildScrollView(
                child: _StatCardGrid(stats: stats),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  ErrorState(onRetry: () => ref.invalidate(adminStatsProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardGrid extends StatelessWidget {
  const _StatCardGrid({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    // Registered players and clubs lead, because they are the numbers the
    // dashboard exists to answer; the moderation counts follow.
    final cards = <_StatCardData>[
      _StatCardData(
        label: 'Registered players',
        value: stats.players,
        icon: Icons.person_outline,
        color: AppColors.brandBlue,
        footnote: '${stats.playerProfiles} with a profile',
      ),
      _StatCardData(
        label: 'Registered clubs',
        value: stats.clubs,
        icon: Icons.shield_outlined,
        color: AppColors.brandBlueLight,
        footnote: '${stats.clubProfiles} with a profile',
      ),
      _StatCardData(
        label: 'Verified clubs',
        value: stats.verifiedClubs,
        icon: Icons.verified_outlined,
        color: AppColors.success,
      ),
      _StatCardData(
        label: 'Coaches',
        value: stats.coaches,
        icon: Icons.sports,
        color: AppColors.brandBlueDark,
      ),
      _StatCardData(
        label: 'Total accounts',
        value: stats.totalUsers,
        icon: Icons.groups_outlined,
        color: AppColors.grey,
      ),
      _StatCardData(
        label: 'Suspended accounts',
        value: stats.suspended,
        icon: Icons.block_outlined,
        color: AppColors.error,
      ),
      _StatCardData(
        label: 'Moderators',
        value: stats.moderators,
        icon: Icons.gavel_outlined,
        color: AppColors.warning,
      ),
      _StatCardData(
        label: 'Community posts',
        value: stats.posts,
        icon: Icons.photo_library_outlined,
        color: AppColors.brandBlue,
        footnote: '${stats.hiddenPosts} hidden',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Whole cards only: the grid picks a column count that fits at a
        // ~260px minimum rather than letting a fixed count squash the cards
        // on a narrower window.
        final columns = (constraints.maxWidth / 260).floor().clamp(1, 4);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.9,
          children: [for (final card in cards) _StatCard(data: card)],
        );
      },
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.footnote,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  /// A secondary number that qualifies [value] — e.g. how many of the
  /// registered players have actually filled in a profile.
  final String? footnote;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.profileColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderOnSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${data.value}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  data.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                if (data.footnote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      data.footnote!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
