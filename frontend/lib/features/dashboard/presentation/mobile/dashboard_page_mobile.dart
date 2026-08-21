import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../club/application/club_profile_controller.dart';
import '../../../club_players/application/club_players_controller.dart';
import '../../../club_players/domain/entities/club_dashboard_summary.dart';
import '../../../home_feed/domain/entities/feed_item.dart';
import '../../../home_feed/presentation/mobile/home_feed_page_mobile.dart';
import '../../../home_feed/presentation/shared/create_post_sheet.dart';
import '../../../home_feed/presentation/shared/home_feed_body.dart';
import '../shared/club_composer_card.dart';
import '../shared/club_dashboard_widgets.dart';
import '../shared/club_feed_tabs.dart';

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
/// header, composer, content-type tabs, the news feed, then 2-per-row stat
/// tiles, profile completeness, and recent players below. Quick Actions
/// moved to the Club Profile page. Not a shrunk copy of the Desktop layout.
class _ClubDashboardMobile extends ConsumerStatefulWidget {
  const _ClubDashboardMobile();

  @override
  ConsumerState<_ClubDashboardMobile> createState() => _ClubDashboardMobileState();
}

class _ClubDashboardMobileState extends ConsumerState<_ClubDashboardMobile> {
  FeedItemKind? _filter;

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: AppSpacing.md),
          ClubComposerCard(
            logoUrl: profileAsync.maybeWhen(data: (profile) => profile.logoUrl, orElse: () => null),
            onTap: () => CreatePostSheet.show(context, role: UserRole.club),
          ),
          const SizedBox(height: AppSpacing.md),
          ClubFeedTabs(value: _filter, onChanged: (kind) => setState(() => _filter = kind)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 700,
            child: HomeFeedBody(
              role: UserRole.club,
              showComposerFab: false,
              kindFilter: _filter,
              onCreatePost: () => CreatePostSheet.show(context, role: UserRole.club),
            ),
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
        ClubDashboardRecentPlayersSection(summary: summary),
      ],
    );
  }
}
