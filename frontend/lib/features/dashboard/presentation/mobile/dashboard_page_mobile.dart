import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../club/application/club_profile_controller.dart';
import '../../../club/domain/entities/club_profile.dart';
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

/// The Club's operational home on mobile — its own composition, not a
/// collapsed copy of Desktop's 2-column layout. Order: identity header,
/// roster metrics, Quick Actions, the post composer, feed tabs, the feed
/// itself, then completeness/recent players as trailing "more detail"
/// content — the feed and its immediate controls sit together as one
/// visual unit instead of being split apart by the stats block.
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
          profileAsync.when(
            data: (profile) => _ClubHomeHeaderMobile(profile: profile),
            loading: () => const SkeletonBox(height: 52),
            error: (error, _) =>
                ErrorState(onRetry: () => ref.invalidate(clubProfileControllerProvider)),
          ),
          const SizedBox(height: AppSpacing.lg),
          summaryAsync.when(
            data: (summary) => _StatsGridMobile(summary: summary),
            loading: () => const _StatsGridSkeleton(),
            error: (error, _) =>
                ErrorState(onRetry: () => ref.invalidate(clubDashboardSummaryProvider)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.dashboardQuickActionsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final action in clubDashboardQuickActions(l10n)) ...[
            ClubQuickActionCard(action: action),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.dashboardLatestNewsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ClubComposerCard(
            logoUrl: profileAsync.maybeWhen(data: (profile) => profile.logoUrl, orElse: () => null),
            onTap: () => CreatePostSheet.show(context, role: UserRole.club),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClubFeedTabs(value: _filter, onChanged: (kind) => setState(() => _filter = kind)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 640,
            child: HomeFeedBody(
              role: UserRole.club,
              showComposerFab: false,
              kindFilter: _filter,
              onCreatePost: () => CreatePostSheet.show(context, role: UserRole.club),
            ),
          ),
          summaryAsync.maybeWhen(
            data: (summary) => summary.averageCompletionPercent == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: ClubDashboardCompletenessCard(summary: summary),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.lg),
          summaryAsync.when(
            data: (summary) => ClubDashboardRecentPlayersSection(summary: summary),
            loading: () => const SkeletonBox(height: 220),
            error: (error, _) =>
                ErrorState(onRetry: () => ref.invalidate(clubDashboardSummaryProvider)),
          ),
        ],
      ),
    );
  }
}

/// Compact identity block for mobile — logo/name/location, plus the same
/// two profile actions Desktop offers, as small icon buttons instead of
/// labeled ones (limited width).
class _ClubHomeHeaderMobile extends StatelessWidget {
  const _ClubHomeHeaderMobile({required this.profile});

  final ClubProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: ClubDashboardIdentityHeader(profile: profile, logoSize: 52)),
        IconButton(
          tooltip: l10n.clubHomeViewPublicProfileLabel,
          onPressed: () => context.push('/clubs/${profile.id}'),
          icon: const Icon(Icons.visibility_outlined),
        ),
        IconButton(
          tooltip: l10n.dashboardEditClubProfile,
          onPressed: () => context.go('/club/edit'),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }
}

/// Roster metrics, 2-per-row — same real data as Desktop's full-width row,
/// just wrapped for mobile's narrow width.
class _StatsGridMobile extends StatelessWidget {
  const _StatsGridMobile({required this.summary});

  final ClubDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = summary.totalPlayers;
    String? percentLabel(int value) =>
        total > 0 ? l10n.clubDashboardPercentOfRosterLabel((value / total * 100).round()) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ClubDashboardStatTile(
                icon: Icons.groups_outlined,
                label: l10n.clubDashboardTotalPlayersLabel,
                value: total,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ClubDashboardStatTile(
                icon: Icons.check_circle_outline,
                label: l10n.clubDashboardCompleteProfilesLabel,
                value: summary.completeProfiles,
                color: AppColors.success,
                subtitle: percentLabel(summary.completeProfiles),
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
                subtitle: percentLabel(summary.incompleteProfiles),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: ClubDashboardSavedPlayersTile()),
          ],
        ),
      ],
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 76)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 76)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 76)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 76)),
          ],
        ),
      ],
    );
  }
}
