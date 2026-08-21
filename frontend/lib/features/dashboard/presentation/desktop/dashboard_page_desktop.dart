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
import '../../../home_feed/presentation/desktop/home_feed_page_desktop.dart';
import '../../../home_feed/presentation/shared/create_post_sheet.dart';
import '../../../home_feed/presentation/shared/home_feed_body.dart';
import '../shared/club_composer_card.dart';
import '../shared/club_dashboard_widgets.dart';
import '../shared/club_feed_tabs.dart';

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

/// The Club's operational home — a 3-column social-feed layout (the app
/// shell already provides column 1, the persistent left sidebar):
/// column 2 is the feed itself (composer, content-type tabs, posts),
/// column 3 is a compact "at a glance" summary (identity, roster stats,
/// completeness, recently added players). Quick Actions live on the Club
/// Profile page instead (see [ClubQuickActionCard]) — this column stays
/// secondary to the feed, not a second copy of the dashboard.
class _ClubDashboardDesktop extends ConsumerStatefulWidget {
  const _ClubDashboardDesktop();

  @override
  ConsumerState<_ClubDashboardDesktop> createState() => _ClubDashboardDesktopState();
}

class _ClubDashboardDesktopState extends ConsumerState<_ClubDashboardDesktop> {
  FeedItemKind? _filter;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(clubDashboardSummaryProvider);
    final profileAsync = ref.watch(clubProfileControllerProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        profileAsync.maybeWhen(
                          data: (profile) => ClubDashboardIdentityHeader(profile: profile),
                          orElse: () => const SkeletonBox(height: 64),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ClubComposerCard(
                          logoUrl: profileAsync.maybeWhen(
                            data: (profile) => profile.logoUrl,
                            orElse: () => null,
                          ),
                          onTap: () => CreatePostSheet.show(context, role: UserRole.club),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ClubFeedTabs(
                          value: _filter,
                          onChanged: (kind) => setState(() => _filter = kind),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 900,
                          child: HomeFeedBody(
                            role: UserRole.club,
                            showComposerFab: false,
                            kindFilter: _filter,
                            onCreatePost: () => CreatePostSheet.show(context, role: UserRole.club),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: summaryAsync.when(
                    data: (summary) => _ClubHomeSidebar(summary: summary),
                    loading: () => const _ClubHomeSidebarSkeleton(),
                    error: (error, _) => ErrorState(
                      onRetry: () => ref.invalidate(clubDashboardSummaryProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Column 3's content: roster stats (2x2), profile completeness, and
/// recently added players — the same real data the old single-column
/// dashboard showed, just laid out for a narrow column instead of a wide
/// row.
class _ClubHomeSidebar extends StatelessWidget {
  const _ClubHomeSidebar({required this.summary});

  final ClubDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.dashboardStatsTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(width: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: ClubDashboardSavedPlayersTile()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClubDashboardCompletenessCard(summary: summary),
          const SizedBox(height: AppSpacing.lg),
        ],
        ClubDashboardRecentPlayersSection(summary: summary),
      ],
    );
  }
}

class _ClubHomeSidebarSkeleton extends StatelessWidget {
  const _ClubHomeSidebarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 76)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: SkeletonBox(height: 76)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 76)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: SkeletonBox(height: 76)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(height: 220),
      ],
    );
  }
}
