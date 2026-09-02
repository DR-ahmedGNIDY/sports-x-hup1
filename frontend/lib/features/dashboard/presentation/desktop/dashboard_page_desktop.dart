import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../club/application/club_profile_controller.dart';
import '../../../club/domain/entities/club_profile.dart';
import '../../../player/application/player_profile_controller.dart';
import '../../../player/domain/entities/player_profile.dart';
import '../../../club_players/application/club_players_controller.dart';
import '../../../club_players/domain/entities/club_dashboard_summary.dart';
import '../../../home_feed/domain/entities/feed_item.dart';
import '../../../home_feed/presentation/shared/create_post_sheet.dart';
import '../../../home_feed/presentation/shared/feed_layout.dart';
import '../../../home_feed/presentation/shared/home_feed_slivers.dart';
import '../shared/composer_card.dart';
import '../shared/club_dashboard_widgets.dart';
import '../shared/feed_tabs.dart';
import '../shared/club_news_columns.dart';

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

    // Same split as mobile: the profile numbers stay on the Player Profile
    // page, and Home gains an identity and somewhere to post from.
    if (user?.role == UserRole.player) {
      return const _PlayerDashboardDesktop();
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

/// Page gutter and content cap for the Club's Home. Capped rather than
/// full-bleed so the two columns stay a readable width on a wide monitor —
/// and, like every other width on this page, expressed in logical pixels
/// so the whole layout scales together under browser zoom.
const double _pageMaxWidth = 1160;
const double _pageGutter = 28;

/// The Club's operational home — Dashboard **and** Feed, not one instead
/// of the other. Top to bottom: identity (full width), roster metrics
/// (full width), roster completeness (full width — Quick Actions live on
/// the Club Profile page instead, not duplicated here), then the news
/// section: the feed (main column, capped at [FeedLayout.columnMaxWidth])
/// beside Recent Players (secondary column).
///
/// The page is one scroll, all the way down, built from slivers. Earlier
/// versions gave the feed row an explicit height — first `Expanded` inside
/// a non-scrolling Column (which squeezed the feed to nothing on short
/// viewports), then a height computed from the viewport and clamped. Both
/// are the same mistake in different clothes: an embedded feed with a
/// height of its own is a second scroll view inside the page, and a height
/// derived from the viewport is a constraint that doesn't scale with the
/// content around it. `SliverCrossAxisGroup` gives the two columns their
/// side-by-side layout *within* the page's own scroll, so neither column
/// needs a height at all.
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
        child: FeedRefreshIndicator(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(_pageGutter, _pageGutter, _pageGutter, 0),
                sliver: SliverToBoxAdapter(
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
                      summaryAsync.maybeWhen(
                        data: (summary) => summary.averageCompletionPercent == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.lg),
                                child: ClubDashboardCompletenessCard(summary: summary),
                              ),
                        orElse: () => const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.lg),
                          child: SkeletonBox(height: 100),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.dashboardLatestNewsTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(_pageGutter, 0, _pageGutter, _pageGutter),
                // Two columns inside the page's own scroll: no heights, no
                // nested scroll views. The feed column is flexible but
                // capped, so it scales down with the window and stops
                // growing once it reaches a readable width.
                sliver: ClubNewsColumns(
                  // Composer, tabs and cards share one cap, so they line
                  // up edge to edge instead of the cards sitting inset
                  // inside their own column.
                  feed: FeedColumnSliver(
                    kindFilter: _filter,
                    onCreatePost: () => CreatePostSheet.show(context, role: UserRole.club),
                    header: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ComposerCard(
                          logoUrl: profileAsync.maybeWhen(
                            data: (profile) => profile.logoUrl,
                            orElse: () => null,
                          ),
                          onTap: () => CreatePostSheet.show(context, role: UserRole.club),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FeedTabs(
                          value: _filter,
                          onChanged: (kind) => setState(() => _filter = kind),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                  secondary: SliverToBoxAdapter(
                    child: summaryAsync.when(
                      data: (summary) => ClubDashboardRecentPlayersSection(summary: summary),
                      loading: () => const SkeletonBox(height: 300),
                      error: (error, _) => ErrorState(
                        onRetry: () => ref.invalidate(clubDashboardSummaryProvider),
                      ),
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

/// The Player's Home on desktop — the Club's page with the roster half
/// removed, which on this layout means one column rather than two.
///
/// `ClubNewsColumns` exists to put the feed beside the recent-players
/// panel. A player has nothing to put in that second column, and a
/// two-column grid with one side empty reads as a layout that failed to
/// load rather than as a deliberately simpler page — so the feed runs on
/// its own, centred, at the same column width it has beside the panel.
class _PlayerDashboardDesktop extends ConsumerStatefulWidget {
  const _PlayerDashboardDesktop();

  @override
  ConsumerState<_PlayerDashboardDesktop> createState() =>
      _PlayerDashboardDesktopState();
}

class _PlayerDashboardDesktopState
    extends ConsumerState<_PlayerDashboardDesktop> {
  FeedItemKind? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(playerProfileControllerProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
        child: FeedRefreshIndicator(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  _pageGutter,
                  _pageGutter,
                  _pageGutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      profileAsync.when(
                        data: (profile) => _PlayerHomeHeader(profile: profile),
                        loading: () => const SkeletonBox(height: 72),
                        error: (error, _) => ErrorState(
                          onRetry: () =>
                              ref.invalidate(playerProfileControllerProvider),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.dashboardLatestNewsTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  _pageGutter,
                  0,
                  _pageGutter,
                  _pageGutter,
                ),
                sliver: FeedColumnSliver(
                  kindFilter: _filter,
                  onCreatePost: () =>
                      CreatePostSheet.show(context, role: UserRole.player),
                  header: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ComposerCard(
                        isClub: false,
                        logoUrl: profileAsync.maybeWhen(
                          data: (profile) => profile.profilePhoto?.secureUrl,
                          orElse: () => null,
                        ),
                        onTap: () => CreatePostSheet.show(
                          context,
                          role: UserRole.player,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FeedTabs(
                        value: _filter,
                        onChanged: (kind) => setState(() => _filter = kind),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
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

/// The Player's counterpart to [_ClubHomeHeader]: photo, name, what they
/// play and where, and the same two actions.
class _PlayerHomeHeader extends StatelessWidget {
  const _PlayerHomeHeader({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.profileColors;
    final photoUrl = profile.profilePhoto?.secureUrl;
    final name = profile.fullName.isEmpty
        ? l10n.unnamedPlayer
        : profile.fullName;
    final subtitle = [
      profile.sport,
      profile.city,
      profile.country,
    ].where((v) => v != null && v.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: colors.surface,
              backgroundImage: photoUrl != null
                  ? appImageProvider(
                      photoUrl,
                      context: context,
                      decodeWidth: AppImageSize.avatarLarge,
                    )
                  : null,
              child: photoUrl == null
                  ? Icon(Icons.person, color: colors.textMuted, size: 30)
                  : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/players/${profile.id}'),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.previewLabel),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => context.go('/player/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.dashboardEditProfile),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Divider(color: colors.borderOnSurface.withValues(alpha: 0.08)),
      ],
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
