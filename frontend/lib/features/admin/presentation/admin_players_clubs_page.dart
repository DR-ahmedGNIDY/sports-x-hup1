import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/admin_clubs_controller.dart';
import '../application/admin_stats_controller.dart';
import '../application/admin_players_controller.dart';
import '../domain/entities/admin_club_summary.dart';
import '../domain/entities/admin_player_summary.dart';

/// Desktop only — same rationale as [AdminUsersPage].
class AdminPlayersClubsPage extends StatelessWidget {
  const AdminPlayersClubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.dashboardAdminPlayersClubs, style: Theme.of(context).textTheme.headlineSmall),
                TextButton.icon(
                  onPressed: () => context.go('/admin/users'),
                  icon: const Icon(Icons.people_outline),
                  label: Text(l10n.usersTabLabel),
                ),
              ],
            ),
            TabBar(
              tabs: [Tab(text: l10n.playersTabLabel), Tab(text: l10n.clubsTabLabel)],
            ),
            const Expanded(
              child: TabBarView(children: [_PlayersTab(), _ClubsTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayersTab extends ConsumerWidget {
  const _PlayersTab();

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AdminPlayerSummary player,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removePlayerProfileTitle),
        content: Text(
          l10n.removePlayerProfileContent(
            player.fullName.isEmpty ? l10n.thisPlayerFallback : player.fullName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.removeProfileTooltip),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(adminPlayersControllerProvider.notifier).deletePlayer(player.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playersAsync = ref.watch(adminPlayersControllerProvider);

    return playersAsync.when(
      data: (players) {
        if (players.isEmpty) {
          return Center(child: Text(l10n.noPlayerProfilesFound));
        }
        final hasMore = ref.watch(adminPlayersControllerProvider.notifier).hasMore;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.nameColumnLabel)),
                    DataColumn(label: Text(l10n.sportColumnLabel)),
                    DataColumn(label: Text(l10n.positionColumnLabel)),
                    DataColumn(label: Text(l10n.visibilityColumnLabel)),
                    DataColumn(label: Text(l10n.actionsColumnLabel)),
                  ],
                  rows: players
                      .map(
                        (player) => DataRow(
                          cells: [
                            DataCell(
                              Text(player.fullName.isEmpty ? l10n.unnamedShort : player.fullName),
                            ),
                            DataCell(Text(player.sport ?? '')),
                            DataCell(Text(player.position ?? '')),
                            DataCell(Text(player.visibility ?? '')),
                            DataCell(
                              IconButton(
                                tooltip: l10n.removeProfileTooltip,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(context, ref, player),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: OutlinedButton(
                      onPressed: () =>
                          ref.read(adminPlayersControllerProvider.notifier).loadMore(),
                      child: Text(l10n.loadMoreLabel),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(adminPlayersControllerProvider)),
    );
  }
}

class _ClubsTab extends ConsumerWidget {
  const _ClubsTab();

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AdminClubSummary club,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeClubProfileTitle),
        content: Text(
          l10n.removeClubProfileContent(
            club.name?.isNotEmpty == true ? club.name! : l10n.thisClubFallback,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.removeProfileTooltip),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(adminClubsControllerProvider.notifier).deleteClub(club.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final clubsAsync = ref.watch(adminClubsControllerProvider);

    return clubsAsync.when(
      data: (clubs) {
        if (clubs.isEmpty) {
          return Center(child: Text(l10n.noClubProfilesFound));
        }
        final hasMore = ref.watch(adminClubsControllerProvider.notifier).hasMore;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.nameColumnLabel)),
                    DataColumn(label: Text(l10n.countryLabel)),
                    DataColumn(label: Text(l10n.cityLabel)),
                    DataColumn(label: Text(l10n.verifiedColumnLabel)),
                    DataColumn(label: Text(l10n.actionsColumnLabel)),
                  ],
                  rows: clubs
                      .map(
                        (club) => DataRow(
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    club.name?.isNotEmpty == true
                                        ? club.name!
                                        : l10n.unnamedShort,
                                  ),
                                  // The same badge the rest of the app
                                  // shows, so the admin sees exactly what
                                  // granting verification produces.
                                  if (club.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const VerifiedBadge(size: 16),
                                  ],
                                ],
                              ),
                            ),
                            DataCell(Text(club.country ?? '')),
                            DataCell(Text(club.city ?? '')),
                            DataCell(
                              Switch(
                                value: club.isVerified,
                                onChanged: (value) async {
                                  await ref
                                      .read(adminClubsControllerProvider.notifier)
                                      .setVerified(club.id, value);
                                  ref.invalidate(adminStatsProvider);
                                },
                              ),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: l10n.removeProfileTooltip,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(context, ref, club),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: OutlinedButton(
                      onPressed: () =>
                          ref.read(adminClubsControllerProvider.notifier).loadMore(),
                      child: Text(l10n.loadMoreLabel),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(adminClubsControllerProvider)),
    );
  }
}
