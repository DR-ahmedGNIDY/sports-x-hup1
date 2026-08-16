import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/club_players_controller.dart';
import '../shared/club_managed_player_card.dart';
import '../shared/club_players_pagination.dart';
import '../shared/club_players_toolbar.dart';

class ClubPlayersPageDesktop extends ConsumerWidget {
  const ClubPlayersPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(clubPlayersControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.clubPlayersTitle, style: Theme.of(context).textTheme.headlineSmall),
                  FilledButton.icon(
                    onPressed: () => context.go('/club/players/new'),
                    icon: const Icon(Icons.person_add_outlined),
                    label: Text(l10n.clubPlayersAddPlayerLabel),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const ClubPlayersToolbar(),
              const SizedBox(height: 12),
              Expanded(
                child: rosterAsync.when(
                  data: (roster) {
                    final filtersActive = clubPlayersFiltersActive(
                      ref.read(clubPlayersControllerProvider.notifier).filters,
                    );
                    if (roster.items.isEmpty) {
                      return Center(
                        child: Text(
                          filtersActive
                              ? l10n.clubPlayersNoSearchResults
                              : l10n.clubPlayersEmptyState,
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(clubPlayersControllerProvider.notifier).refresh(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: roster.items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  ClubManagedPlayerCard(player: roster.items[index]),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ClubPlayersPagination(page: roster),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorState(
                    onRetry: () => ref.read(clubPlayersControllerProvider.notifier).refresh(),
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
