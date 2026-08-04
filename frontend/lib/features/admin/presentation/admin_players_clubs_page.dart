import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/admin_clubs_controller.dart';
import '../application/admin_players_controller.dart';
import '../domain/entities/admin_club_summary.dart';
import '../domain/entities/admin_player_summary.dart';

/// Desktop only — same rationale as [AdminUsersPage].
class AdminPlayersClubsPage extends StatelessWidget {
  const AdminPlayersClubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin — Players & Clubs'),
          leading: BackButton(onPressed: () => context.go('/dashboard')),
          actions: [
            TextButton.icon(
              onPressed: () => context.go('/admin/users'),
              icon: const Icon(Icons.people_outline),
              label: const Text('Users'),
            ),
            const SizedBox(width: 16),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Players'), Tab(text: 'Clubs')],
          ),
        ),
        body: const TabBarView(children: [_PlayersTab(), _ClubsTab()]),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove player profile?'),
        content: Text(
          'This permanently deletes the profile for '
          '${player.fullName.isEmpty ? 'this player' : player.fullName}, '
          'including their photos and videos. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
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
    final playersAsync = ref.watch(adminPlayersControllerProvider);

    return playersAsync.when(
      data: (players) {
        if (players.isEmpty) {
          return const Center(child: Text('No player profiles found.'));
        }
        final hasMore = ref.watch(adminPlayersControllerProvider.notifier).hasMore;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Sport')),
                    DataColumn(label: Text('Position')),
                    DataColumn(label: Text('Visibility')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: players
                      .map(
                        (player) => DataRow(
                          cells: [
                            DataCell(
                              Text(player.fullName.isEmpty ? 'Unnamed' : player.fullName),
                            ),
                            DataCell(Text(player.sport ?? '')),
                            DataCell(Text(player.position ?? '')),
                            DataCell(Text(player.visibility ?? '')),
                            DataCell(
                              IconButton(
                                tooltip: 'Remove profile',
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
                      child: const Text('Load more'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove club profile?'),
        content: Text(
          'This permanently deletes the profile for '
          '${club.name?.isNotEmpty == true ? club.name! : 'this club'}, '
          'including its logo. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
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
    final clubsAsync = ref.watch(adminClubsControllerProvider);

    return clubsAsync.when(
      data: (clubs) {
        if (clubs.isEmpty) {
          return const Center(child: Text('No club profiles found.'));
        }
        final hasMore = ref.watch(adminClubsControllerProvider.notifier).hasMore;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Country')),
                    DataColumn(label: Text('City')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: clubs
                      .map(
                        (club) => DataRow(
                          cells: [
                            DataCell(
                              Text(club.name?.isNotEmpty == true ? club.name! : 'Unnamed'),
                            ),
                            DataCell(Text(club.country ?? '')),
                            DataCell(Text(club.city ?? '')),
                            DataCell(
                              IconButton(
                                tooltip: 'Remove profile',
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
                      child: const Text('Load more'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
    );
  }
}
