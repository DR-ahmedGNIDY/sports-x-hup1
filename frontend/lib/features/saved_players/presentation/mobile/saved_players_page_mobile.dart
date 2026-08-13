import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/presentation/shared/player_search_result_card.dart';
import '../../application/saved_players_controller.dart';

class SavedPlayersPageMobile extends ConsumerWidget {
  const SavedPlayersPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlayersControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(l10n.dashboardSavedPlayers, style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: savedAsync.when(
            data: (players) => players.isEmpty
                ? const Center(child: Text('You have not saved any players yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
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
    );
  }
}
