import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../player/presentation/shared/player_search_result_card.dart';
import '../../application/saved_players_controller.dart';

class SavedPlayersPageMobile extends ConsumerWidget {
  const SavedPlayersPageMobile({super.key});

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
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: players.length,
                itemBuilder: (context, index) =>
                    PlayerSearchResultCard(player: players[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
