import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../l10n/generated/app_localizations.dart';
import '../../../club_players/domain/entities/club_dashboard_summary.dart';
import '../../../club_players/domain/entities/club_managed_player.dart';

/// One stat in the Club Dashboard's summary row (total / complete /
/// incomplete players). Desktop lays these out side by side; Mobile wraps
/// them 2-per-row — see the platform dashboard files for the container.
class ClubDashboardStatTile extends StatelessWidget {
  const ClubDashboardStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = color ?? colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: tint.withValues(alpha: 0.12),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$value', style: Theme.of(context).textTheme.headlineSmall),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the Club Dashboard's "Recently added players" list — a
/// lighter read-only variant of [ClubManagedPlayerCard] (no resend-
/// credentials action; tapping opens the full roster instead).
class ClubDashboardRecentPlayerTile extends StatelessWidget {
  const ClubDashboardRecentPlayerTile({super.key, required this.player});

  final ClubManagedPlayer player;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final profile = player.profile;
    final fullName = profile.fullName.isEmpty ? profile.contact.phone ?? '' : profile.fullName;
    final subtitle = [
      profile.sport,
      profile.position,
    ].where((v) => v != null && v.isNotEmpty).join(' · ');
    final addedAt = profile.createdAt;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: colorScheme.surfaceContainerHighest,
        backgroundImage: profile.profilePhoto != null
            ? NetworkImage(profile.profilePhoto!.secureUrl)
            : null,
        child: profile.profilePhoto == null
            ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
            : null,
      ),
      title: Text(fullName, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, overflow: TextOverflow.ellipsis) : null,
      trailing: addedAt != null
          ? Text(
              l10n.clubDashboardAddedOnLabel(DateFormat.MMMd().format(addedAt.toLocal())),
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: () => context.go('/club/players'),
    );
  }
}

/// The "Recently added players" section body — title row (+ "View all"
/// once there are players) followed by either the empty-state hint or a
/// card list of [ClubDashboardRecentPlayerTile]s. Desktop and Mobile were
/// rendering this identically inside their own `_ClubDashboardBody`, so it
/// now lives here once; only the surrounding stat-tile/quick-action layout
/// around it still differs per platform.
class ClubDashboardRecentPlayersSection extends StatelessWidget {
  const ClubDashboardRecentPlayersSection({super.key, required this.summary});

  final ClubDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            padding: const EdgeInsets.symmetric(vertical: 16),
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

/// A single Quick Action entry — data only, so Desktop/Mobile can render
/// it as a grid tile or a list row without duplicating the action list
/// itself.
class ClubQuickAction {
  const ClubQuickAction({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;
}

/// The 5 daily Club actions this dashboard exists to surface, per the
/// Club Product Report: Add Player, Club Players, Search Players, Saved
/// Players, Edit Club Profile — in priority order.
List<ClubQuickAction> clubDashboardQuickActions(AppLocalizations l10n) => [
  ClubQuickAction(
    icon: Icons.person_add_outlined,
    label: l10n.clubPlayersAddPlayerLabel,
    route: '/club/players/new',
  ),
  ClubQuickAction(
    icon: Icons.groups_outlined,
    label: l10n.clubPlayersTitle,
    route: '/club/players',
  ),
  ClubQuickAction(
    icon: Icons.search_outlined,
    label: l10n.dashboardSearchPlayers,
    route: '/search',
  ),
  ClubQuickAction(
    icon: Icons.bookmark_outline,
    label: l10n.dashboardSavedPlayers,
    route: '/saved-players',
  ),
  ClubQuickAction(
    icon: Icons.edit_outlined,
    label: l10n.dashboardEditClubProfile,
    route: '/club/edit',
  ),
];
