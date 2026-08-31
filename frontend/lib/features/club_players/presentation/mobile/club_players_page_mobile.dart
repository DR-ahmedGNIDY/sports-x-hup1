import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/club_players_controller.dart';
import '../shared/club_managed_player_card.dart';
import '../shared/club_players_pagination.dart';
import '../shared/club_players_toolbar.dart';

class ClubPlayersPageMobile extends ConsumerWidget {
  const ClubPlayersPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(clubPlayersControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          // Titled by the shell's app bar; the action stays, labelled rather
          // than a bare icon now that no adjacent title lends it context.
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => context.go('/club/players/new'),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l10n.clubPlayersAddPlayerLabel),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: const ClubPlayersToolbar(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: rosterAsync.when(
            data: (roster) {
              final filtersActive = clubPlayersFiltersActive(
                ref.read(clubPlayersControllerProvider.notifier).filters,
              );
              if (roster.items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      filtersActive ? l10n.clubPlayersNoSearchResults : l10n.clubPlayersEmptyState,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(clubPlayersControllerProvider.notifier).refresh(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: roster.items.length,
                        itemBuilder: (context, index) =>
                            ClubManagedPlayerCard(player: roster.items[index]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClubPlayersPagination(page: roster),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                ErrorState(onRetry: () => ref.read(clubPlayersControllerProvider.notifier).refresh()),
          ),
        ),
      ],
    );
  }
}
