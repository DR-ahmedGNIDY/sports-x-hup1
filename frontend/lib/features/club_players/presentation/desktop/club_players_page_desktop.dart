import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../application/club_players_controller.dart';
import '../shared/club_managed_player_card.dart';

class ClubPlayersPageDesktop extends ConsumerWidget {
  const ClubPlayersPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(clubPlayersControllerProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('لاعبو النادي', style: Theme.of(context).textTheme.headlineSmall),
                  FilledButton.icon(
                    onPressed: () => context.go('/club/players/new'),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('إضافة لاعب'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: playersAsync.when(
                  data: (players) => players.isEmpty
                      ? const Center(child: Text('لم تتم إضافة أي لاعب بعد.'))
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(clubPlayersControllerProvider.notifier).refresh(),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: players.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                ClubManagedPlayerCard(player: players[index]),
                          ),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorState(
                    onRetry: () => ref.invalidate(clubPlayersControllerProvider),
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
