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
import '../../../home_feed/presentation/mobile/home_feed_page_mobile.dart';
import '../../../home_feed/presentation/shared/create_post_sheet.dart';
import '../../../home_feed/presentation/shared/home_feed_body.dart';
import '../shared/club_dashboard_widgets.dart';

/// Content-only — the top bar/bottom nav chrome that used to live here now
/// lives in `AppShell` (mounted once by the `/dashboard` ShellRoute), so
/// this widget is just the Player/Club/Admin dashboard body.
class DashboardPageMobile extends ConsumerWidget {
  const DashboardPageMobile({super.key});

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
      return const HomeFeedPageMobile();
    }
    if (user?.role == UserRole.club) {
      return const _ClubDashboardMobile();
    }
    if (user?.role == UserRole.admin) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.dashboardTitleWithRole(l10n.dashboardRoleAdmin)),
            const SizedBox(height: 8),
            Text(l10n.dashboardAdminMobileHint),
          ],
        ),
      );
    }
    return Center(child: Text(l10n.dashboardComingSoon(roleLabel)));
  }
}

/// The Club's operational home on mobile — same data as Desktop
/// ([ClubDashboardSummary]), but stacked single-column: compact identity
/// header, 2-per-row stat tiles, a vertical quick-action list with
/// descriptions, profile completeness, then recent players. Not a shrunk
/// copy of the Desktop grid layout.
class _ClubDashboardMobile extends ConsumerWidget {
  const _ClubDashboardMobile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(clubDashboardSummaryProvider);
    final profileAsync = ref.watch(clubProfileControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          profileAsync.maybeWhen(
            data: (profile) => ClubDashboardIdentityHeader(profile: profile, logoSize: 52),
            orElse: () => const SkeletonBox(height: 52),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => CreatePostSheet.show(context, role: UserRole.club),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(l10n.homeFeedNewPostTitle),
          ),
          const SizedBox(height: 16),
          Text(l10n.dashboardLatestNewsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 600,
            child: HomeFeedBody(role: UserRole.club, showComposerFab: false),
          ),
          const SizedBox(height: 20),
          Text(l10n.dashboardStatsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          summaryAsync.when(
            data: (summary) => _ClubDashboardBody(summary: summary),
            loading: () => const _ClubDashboardSkeleton(),
            error: (error, _) => ErrorState(
              onRetry: () => ref.invalidate(clubDashboardSummaryProvider),
            ),
          ),
        ],
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
          children: const [
            Expanded(child: SkeletonBox(height: 68)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 68)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 68)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 68)),
          ],
        ),
        const SizedBox(height: 20),
        const SkeletonBox(height: 220),
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
              const SizedBox(width: 8),
              Expanded(
                child: ClubDashboardStatTile(
                  icon: Icons.check_circle_outline,
                  label: l10n.clubDashboardCompleteProfilesLabel,
                  value: summary.completeProfiles,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClubDashboardStatTile(
                  icon: Icons.error_outline,
                  label: l10n.clubDashboardIncompleteProfilesLabel,
                  value: summary.incompleteProfiles,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: ClubDashboardSavedPlayersTile()),
            ],
          ),
          const SizedBox(height: 20),
          ClubDashboardCompletenessCard(summary: summary),
          const SizedBox(height: 20),
        ],
        Text(l10n.dashboardQuickActionsTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final action in quickActions)
                ListTile(
                  leading: Icon(action.icon, color: Theme.of(context).colorScheme.primary),
                  title: Text(action.label),
                  subtitle: Text(action.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(action.route),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ClubDashboardRecentPlayersSection(summary: summary),
      ],
    );
  }
}
