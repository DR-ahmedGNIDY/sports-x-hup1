import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../club/domain/entities/club_profile.dart';
import '../../../club/presentation/shared/club_level_labels.dart';
import '../../../club_players/domain/entities/club_dashboard_summary.dart';
import '../../../club_players/domain/entities/club_managed_player.dart';
import '../../../player/presentation/shared/player_enum_labels.dart';
import '../../../saved_players/application/saved_players_controller.dart';

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
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color? color;

  /// Small supporting line under the label (e.g. "77% of roster") — omitted
  /// when there's nothing meaningful to show (an empty roster, or a metric
  /// with no natural percentage-of-total reading).
  final String? subtitle;

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
              radius: 22,
              backgroundColor: tint.withValues(alpha: 0.12),
              child: Icon(icon, color: tint, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Club Dashboard's identity header — logo, name, and whatever location/
/// founded-year/level fields the club has actually filled in. Only real
/// [ClubProfile] fields are shown; nothing is invented for clubs with a
/// sparse profile.
class ClubDashboardIdentityHeader extends StatelessWidget {
  const ClubDashboardIdentityHeader({super.key, required this.profile, this.logoSize = 64});

  final ClubProfile profile;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final location = [
      profile.city,
      profile.country,
    ].where((v) => v != null && v.isNotEmpty).join(', ');
    final metaParts = [
      if (location.isNotEmpty) location,
      if (profile.foundedYear != null) l10n.clubDashboardFoundedLabel(profile.foundedYear!),
      ?clubLevelDisplayValue(l10n, profile.level),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            image: profile.logoUrl != null
                ? DecorationImage(image: appImageProvider(profile.logoUrl!, context: context, decodeWidth: AppImageSize.avatarLarge), fit: BoxFit.cover)
                : null,
          ),
          child: profile.logoUrl == null
              ? Icon(Icons.shield_outlined, color: colorScheme.onSurfaceVariant, size: logoSize * 0.4)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile.name?.isNotEmpty == true ? profile.name! : l10n.unnamedClub,
                style: textTheme.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
              if (metaParts.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  metaParts.join(' · '),
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The Dashboard's 4th stat tile — the club's shortlist size. Reads the
/// already-loaded [savedPlayersControllerProvider] list rather than adding a
/// new backend count endpoint, since `GET /saved-players/me` is a small
/// shortlist, not a paginated collection.
class ClubDashboardSavedPlayersTile extends ConsumerWidget {
  const ClubDashboardSavedPlayersTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final savedCount = ref.watch(savedPlayersControllerProvider).value?.length ?? 0;
    return ClubDashboardStatTile(
      icon: Icons.bookmark_outline,
      label: l10n.dashboardSavedPlayers,
      value: savedCount,
    );
  }
}

/// The Dashboard's roster-wide profile-completeness card — an average of
/// each managed player's own completion percentage (the exact check
/// `GET /players/me/stats` uses), plus the fields most commonly missing
/// across the roster. Renders nothing for an empty roster (nothing to
/// average) rather than showing a fabricated 0%.
class ClubDashboardCompletenessCard extends StatelessWidget {
  const ClubDashboardCompletenessCard({super.key, required this.summary});

  final ClubDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final percent = summary.averageCompletionPercent;
    if (percent == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final progressColor = percent >= 100 ? AppColors.success : colorScheme.primary;
    final missingLabels = summary.topMissingFields
        .map((field) => missingFieldLabel(l10n, field))
        .join(', ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.clubDashboardCompletenessTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: progressColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: progressColor),
                ),
              ],
            ),
            if (missingLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.clubDashboardCompletenessMissingLabel(missingLabels),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
            ? appImageProvider(profile.profilePhoto!.secureUrl, context: context, decodeWidth: AppImageSize.avatarSmall)
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

/// Visual weight for a Quick Action card — [primary] is the one daily action
/// (Add Player), [secondary] the other core jobs (My Players, Find Players),
/// [tertiary] the less-frequent ones (Saved Players, Edit Club Profile).
enum ClubQuickActionEmphasis { primary, secondary, tertiary }

/// A single Quick Action entry — data only, so Desktop/Mobile can render
/// it as a grid tile or a list row without duplicating the action list
/// itself.
class ClubQuickAction {
  const ClubQuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.route,
    required this.emphasis,
  });

  final IconData icon;
  final String label;
  final String description;
  final String route;
  final ClubQuickActionEmphasis emphasis;
}

/// The 5 daily Club actions this dashboard exists to surface, per the
/// Club Product Report: Add Player, Club Players, Search Players, Saved
/// Players, Edit Club Profile — in priority order.
/// A single Quick Action, rendered as a tappable card — used on the Club
/// Profile page's "Quick Actions" section (Desktop grid / Mobile list).
class ClubQuickActionCard extends StatelessWidget {
  const ClubQuickActionCard({super.key, required this.action});

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
              borderRadius: BorderRadius.circular(AppRadius.sm),
              side: BorderSide(color: colorScheme.outlineVariant),
            )
          : null,
      child: InkWell(
        onTap: () => context.go(action.route),
        borderRadius: BorderRadius.circular(AppRadius.sm),
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

List<ClubQuickAction> clubDashboardQuickActions(AppLocalizations l10n) => [
  ClubQuickAction(
    icon: Icons.person_add_outlined,
    label: l10n.clubPlayersAddPlayerLabel,
    description: l10n.clubDashboardAddPlayerDescription,
    route: '/club/players/new',
    emphasis: ClubQuickActionEmphasis.primary,
  ),
  ClubQuickAction(
    icon: Icons.groups_outlined,
    label: l10n.clubPlayersTitle,
    description: l10n.clubDashboardMyPlayersDescription,
    route: '/club/players',
    emphasis: ClubQuickActionEmphasis.secondary,
  ),
  ClubQuickAction(
    icon: Icons.search_outlined,
    label: l10n.dashboardSearchPlayers,
    description: l10n.clubDashboardFindPlayersDescription,
    route: '/search',
    emphasis: ClubQuickActionEmphasis.secondary,
  ),
  ClubQuickAction(
    icon: Icons.bookmark_outline,
    label: l10n.dashboardSavedPlayers,
    description: l10n.clubDashboardSavedPlayersDescription,
    route: '/saved-players',
    emphasis: ClubQuickActionEmphasis.tertiary,
  ),
  ClubQuickAction(
    icon: Icons.edit_outlined,
    label: l10n.dashboardEditClubProfile,
    description: l10n.clubDashboardEditProfileDescription,
    route: '/club/edit',
    emphasis: ClubQuickActionEmphasis.tertiary,
  ),
];
