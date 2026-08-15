import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/club_players_controller.dart';
import '../shared/club_managed_player_card.dart';

class ClubPlayersPageMobile extends ConsumerWidget {
  const ClubPlayersPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(clubPlayersControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.clubPlayersTitle, style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                onPressed: () => context.go('/club/players/new'),
                icon: const Icon(Icons.person_add_outlined),
                tooltip: l10n.clubPlayersAddPlayerLabel,
              ),
            ],
          ),
        ),
        Expanded(
          child: playersAsync.when(
            data: (players) => players.isEmpty
                ? Center(child: Text(l10n.clubPlayersEmptyState))
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(clubPlayersControllerProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: players.length,
                      itemBuilder: (context, index) =>
                          ClubManagedPlayerCard(player: players[index]),
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                ErrorState(onRetry: () => ref.invalidate(clubPlayersControllerProvider)),
          ),
        ),
      ],
    );
  }
}
