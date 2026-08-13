import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/presentation/shared/player_search_result_card.dart';
import '../../application/saved_players_controller.dart';

class SavedPlayersPageDesktop extends ConsumerWidget {
  const SavedPlayersPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlayersControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.dashboardSavedPlayers, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Expanded(
                child: savedAsync.when(
                  data: (players) => players.isEmpty
                      ? const Center(child: Text('You have not saved any players yet.'))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 360,
                            mainAxisExtent: 96,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: players.length,
                          itemBuilder: (context, index) =>
                              PlayerSearchResultCard(player: players[index]),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      ErrorState(onRetry: () => ref.invalidate(savedPlayersControllerProvider)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
