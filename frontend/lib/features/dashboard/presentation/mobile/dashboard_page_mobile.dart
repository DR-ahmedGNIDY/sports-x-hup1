import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../club/application/club_profile_controller.dart';
import '../../../club_players/application/club_players_controller.dart';
import '../../../club_players/domain/entities/club_dashboard_summary.dart';
import '../../../home_feed/presentation/mobile/home_feed_page_mobile.dart';
import '../../../home_feed/presentation/shared/create_post_sheet.dart';
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
/// ([ClubDashboardSummary]), but stacked single-column: 2-per-row stat
/// tiles, a vertical quick-action list, then recent players. Not a
/// shrunk copy of the Desktop grid layout.
class _ClubDashboardMobile extends ConsumerWidget {
  const _ClubDashboardMobile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(clubDashboardSummaryProvider);
    final clubName = ref.watch(clubProfileControllerProvider).value?.name;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (clubName != null && clubName.isNotEmpty)
                ? l10n.dashboardWelcomeMessage(clubName)
                : l10n.dashboardWelcomeMessageNoName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          summaryAsync.when(
            data: (summary) => _ClubDashboardBody(summary: summary),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ErrorState(
              onRetry: () => ref.invalidate(clubDashboardSummaryProvider),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => CreatePostSheet.show(context, role: UserRole.club),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(l10n.homeFeedNewPostTitle),
          ),
        ],
      ),
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
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClubDashboardStatTile(
                  icon: Icons.check_circle_outline,
                  label: l10n.clubDashboardCompleteProfilesLabel,
                  value: summary.completeProfiles,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClubDashboardStatTile(
                  icon: Icons.error_outline,
                  label: l10n.clubDashboardIncompleteProfilesLabel,
                  value: summary.incompleteProfiles,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(action.route),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.clubDashboardRecentPlayersTitle, style: Theme.of(context).textTheme.titleMedium),
            if (summary.totalPlayers > 0)
              TextButton(
                onPressed: () => context.go('/club/players'),
                child: Text(l10n.clubDashboardViewAllLabel),
              ),
          ],
        ),
        if (summary.recentPlayers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.clubDashboardEmptyStateHint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  for (final player in summary.recentPlayers)
                    ClubDashboardRecentPlayerTile(player: player),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
