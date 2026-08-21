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

/// The Club's operational home — Dashboard **and** Feed, not one instead
/// of the other. Top to bottom: identity (full width), roster metrics
/// (full width), roster health + quick actions (full width, sized to
/// their own content — no forced stretching), then a bottom row splitting
/// the feed (main, ~68% width) from Recent Players (secondary, ~32%).
///
/// The whole page is one scroll (`SingleChildScrollView`) — the earlier
/// version made only the bottom row `Expanded` inside a *non-scrolling*
/// Column, so on any viewport where the fixed chrome above it (identity +
/// stats + health/quick-actions) added up to more than the available
/// height, that `Expanded` was squeezed toward zero and the feed
/// effectively vanished. The bottom row now gets an explicit height
/// computed from the real available viewport height (via `LayoutBuilder`,
/// captured before the scroll view so it reflects the actual window, not
/// "whatever's left"), clamped to a sensible range — generous on tall
/// screens, never smaller than enough room for feed cards on short ones.
class _ClubDashboardDesktop extends ConsumerStatefulWidget {
  const _ClubDashboardDesktop();

  @override
  ConsumerState<_ClubDashboardDesktop> createState() => _ClubDashboardDesktopState();
}

class _ClubDashboardDesktopState extends ConsumerState<_ClubDashboardDesktop> {
  FeedItemKind? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(clubDashboardSummaryProvider);
    final profileAsync = ref.watch(clubProfileControllerProvider);

    return LayoutBuilder(
      builder: (context, outer) {
        final feedRowHeight = outer.hasBoundedHeight
            ? (outer.maxHeight * 0.8).clamp(600.0, 980.0)
            : 720.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  profileAsync.when(
                    data: (profile) => _ClubHomeHeader(profile: profile),
                    loading: () => const SkeletonBox(height: 72),
                    error: (error, _) => ErrorState(
                      onRetry: () => ref.invalidate(clubProfileControllerProvider),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  summaryAsync.when(
                    data: (summary) => _ClubHomeStatsRow(summary: summary),
                    loading: () => const _StatsRowSkeleton(),
                    error: (error, _) => ErrorState(
                      onRetry: () => ref.invalidate(clubDashboardSummaryProvider),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  summaryAsync.maybeWhen(
                    data: (summary) => _ClubHomeHealthRow(summary: summary),
                    orElse: () => const SkeletonBox(height: 140),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.dashboardLatestNewsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: feedRowHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClubComposerCard(
                                logoUrl: profileAsync.maybeWhen(
                                  data: (profile) => profile.logoUrl,
                                  orElse: () => null,
                                ),
                                onTap: () => CreatePostSheet.show(context, role: UserRole.club),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClubFeedTabs(
                                value: _filter,
                                onChanged: (kind) => setState(() => _filter = kind),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Expanded(
                                child: HomeFeedBody(
                                  role: UserRole.club,
                                  maxWidth: double.infinity,
                                  showComposerFab: false,
                                  kindFilter: _filter,
                                  onCreatePost: () =>
                                      CreatePostSheet.show(context, role: UserRole.club),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: summaryAsync.when(
                            data: (summary) => SingleChildScrollView(
                              child: ClubDashboardRecentPlayersSection(summary: summary),
                            ),
                            loading: () => const SkeletonBox(height: 300),
                            error: (error, _) => ErrorState(
                              onRetry: () => ref.invalidate(clubDashboardSummaryProvider),
                            ),
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
      },
    );
  }
}

/// Full-width identity block: logo/name/location/founded/level (unchanged
/// data, just given more presence — a larger logo and a divider to close
/// the block off) plus the two profile actions that already exist
/// elsewhere in the app (Edit Profile, View Public Profile), surfaced here
/// since this is the page that should announce "this is your Club".
class _ClubHomeHeader extends StatelessWidget {
  const _ClubHomeHeader({required this.profile});

  final ClubProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: ClubDashboardIdentityHeader(profile: profile, logoSize: 72)),
            const SizedBox(width: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => context.push('/clubs/${profile.id}'),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.clubHomeViewPublicProfileLabel),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () => context.go('/club/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.dashboardEditClubProfile),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
      ],
    );
  }
}

/// The 4 roster metrics as one full-width row — a dashboard metrics strip,
/// not a narrow stack. Complete/Incomplete each get a "% of roster"
/// subtitle (a simple ratio of already-known counts, not a new metric).
class _ClubHomeStatsRow extends StatelessWidget {
  const _ClubHomeStatsRow({required this.summary});

  final ClubDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = summary.totalPlayers;
    String? percentLabel(int value) =>
        total > 0 ? l10n.clubDashboardPercentOfRosterLabel((value / total * 100).round()) : null;

    return Row(
      children: [
        Expanded(
          child: ClubDashboardStatTile(
            icon: Icons.groups_outlined,
            label: l10n.clubDashboardTotalPlayersLabel,
            value: total,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ClubDashboardStatTile(
            icon: Icons.check_circle_outline,
            label: l10n.clubDashboardCompleteProfilesLabel,
            value: summary.completeProfiles,
            color: AppColors.success,
            subtitle: percentLabel(summary.completeProfiles),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ClubDashboardStatTile(
            icon: Icons.error_outline,
            label: l10n.clubDashboardIncompleteProfilesLabel,
            value: summary.incompleteProfiles,
            color: AppColors.warning,
            subtitle: percentLabel(summary.incompleteProfiles),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(child: ClubDashboardSavedPlayersTile()),
      ],
    );
  }
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          const Expanded(child: SkeletonBox(height: 86)),
        ],
      ],
    );
  }
}

/// Roster completeness ("how healthy is my roster?") beside Quick Actions
/// — the two secondary-but-important panels grouped into one row instead
/// of scattered. When there's no completeness data yet (empty roster),
/// Quick Actions takes the full row instead of leaving half of it blank.
///
/// Each panel sizes itself naturally (`CrossAxisAlignment.start`, no
/// `IntrinsicHeight`) — forcing them to match heights previously stretched
/// the shorter panel's cards until they were mostly blank space.
class _ClubHomeHealthRow extends StatelessWidget {
  const _ClubHomeHealthRow({required this.summary});

  final ClubDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quickActions = _QuickActionsGrid(l10n: l10n);

    if (summary.averageCompletionPercent == null) {
      return quickActions;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: ClubDashboardCompletenessCard(summary: summary)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: quickActions),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      // This grid sits in a ~half-dashboard-width column (much wider than
      // the Club Profile page's single-column version), so it needs a
      // taller aspect ratio to land on the same actual card height —
      // otherwise each cell is far taller than its icon+title+description
      // content needs, showing as empty space inside every card.
      childAspectRatio: 4.3,
      children: [
        for (final action in clubDashboardQuickActions(l10n)) ClubQuickActionCard(action: action),
      ],
    );
  }
}
