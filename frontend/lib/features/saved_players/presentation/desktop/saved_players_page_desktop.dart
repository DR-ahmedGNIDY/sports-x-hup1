import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../player/presentation/shared/player_search_result_card.dart';
import '../../application/saved_players_controller.dart';

class SavedPlayersPageDesktop extends ConsumerWidget {
  const SavedPlayersPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlayersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Players'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
      ),
      body: savedAsync.when(
        data: (players) => players.isEmpty
            ? const Center(child: Text('You have not saved any players yet.'))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
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
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
