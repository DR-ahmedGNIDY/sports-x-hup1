import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../club/application/club_profile_controller.dart';
import '../../../club_players/application/club_players_controller.dart';
import '../../../club_players/domain/entities/club_dashboard_summary.dart';
import '../../../home_feed/presentation/desktop/home_feed_page_desktop.dart';
import '../../../home_feed/presentation/shared/create_post_sheet.dart';
import '../shared/club_dashboard_widgets.dart';

/// Content-only — the sidebar/top bar chrome that used to live here now
/// lives in `AppShell` (mounted once by the `/dashboard` ShellRoute), so
/// this widget is just the Player/Club/Admin dashboard body.
class DashboardPageDesktop extends ConsumerWidget {
  const DashboardPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final l10n = AppLocalizations.of(context)!;
    final roleLabel = switch (user?.role) {
      UserRole.club => l10n.roleClub,
      UserRole.admin => l10n.dashboardRoleAdmin,
      _ => l10n.rolePlayer,
    };

    // Player's Home content used to live here (profile completion, stats,
    // quick actions) — it moved to the Player Profile page (see
    // OwnerAccountSection); Home itself is now the activity feed.
    if (user?.role == UserRole.player) {
      return const HomeFeedPageDesktop();
    }
    if (user?.role == UserRole.club) {
      return const _ClubDashboardDesktop();
    }
    if (user?.role == UserRole.admin) {
      return Center(child: Text(l10n.dashboardTitleWithRole(roleLabel)));
    }
    return Center(child: Text(l10n.dashboardComingSoon(roleLabel)));
  }
}

/// The Club's operational home: identity header, roster stats, profile
/// completeness, recently added players, and the 5 daily-use quick actions
/// — see the Club Product Report / Club Experience 2.0 brief for why these
/// replace the old flat button list. Uses the full available width rather
/// than a narrow centered column, matching Desktop's data-dense role.
class _ClubDashboardDesktop extends ConsumerWidget {
  const _ClubDashboardDesktop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(clubDashboardSummaryProvider);
    final profileAsync = ref.watch(clubProfileControllerProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: profileAsync.maybeWhen(
                      data: (profile) => ClubDashboardIdentityHeader(profile: profile),
                      orElse: () => const SkeletonBox(height: 64),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => CreatePostSheet.show(context, role: UserRole.club),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(l10n.homeFeedNewPostTitle),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              summaryAsync.when(
                data: (summary) => _ClubDashboardBody(summary: summary),
                loading: () => const _ClubDashboardSkeleton(),
                error: (error, _) => ErrorState(
                  onRetry: () => ref.invalidate(clubDashboardSummaryProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubDashboardSkeleton extends StatelessWidget {
  const _ClubDashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              const Expanded(child: SkeletonBox(height: 76)),
            ],
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(flex: 2, child: SkeletonBox(height: 260)),
            const SizedBox(width: 24),
            const Expanded(child: SkeletonBox(height: 260)),
          ],
        ),
      ],
    );
  }
}

class _ClubDashboardBody extends StatelessWidget {
  const _ClubDashboardBody({required this.summary});

  final ClubDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quickActions = clubDashboardQuickActions(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary.totalPlayers > 0) ...[
          Row(
            children: [
              Expanded(
                child: ClubDashboardStatTile(
                  icon: Icons.groups_outlined,
                  label: l10n.clubDashboardTotalPlayersLabel,
                  value: summary.totalPlayers,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClubDashboardStatTile(
                  icon: Icons.check_circle_outline,
                  label: l10n.clubDashboardCompleteProfilesLabel,
                  value: summary.completeProfiles,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClubDashboardStatTile(
                  icon: Icons.error_outline,
                  label: l10n.clubDashboardIncompleteProfilesLabel,
                  value: summary.incompleteProfiles,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: ClubDashboardSavedPlayersTile()),
            ],
          ),
          const SizedBox(height: 28),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: ClubDashboardRecentPlayersSection(summary: summary)),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.dashboardQuickActionsTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  for (final action in quickActions) ...[
                    _QuickActionCard(action: action),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (summary.totalPlayers > 0) ...[
          const SizedBox(height: 28),
          ClubDashboardCompletenessCard(summary: summary),
        ],
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final ClubQuickAction action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isPrimary = action.emphasis == ClubQuickActionEmphasis.primary;
    final isTertiary = action.emphasis == ClubQuickActionEmphasis.tertiary;

    return Card(
      margin: EdgeInsets.zero,
      color: isPrimary ? colorScheme.primaryContainer : (isTertiary ? colorScheme.surface : null),
      elevation: isPrimary ? 0 : null,
      shape: isTertiary
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            )
          : null,
      child: InkWell(
        onTap: () => context.go(action.route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                action.icon,
                color: isPrimary ? colorScheme.onPrimaryContainer : colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action.label,
                      style: textTheme.titleSmall?.copyWith(
                        color: isPrimary ? colorScheme.onPrimaryContainer : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: isPrimary ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
