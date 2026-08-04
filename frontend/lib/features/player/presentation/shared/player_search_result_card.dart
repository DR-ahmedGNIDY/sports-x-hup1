import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../saved_players/application/saved_players_controller.dart';
import '../../../saved_players/presentation/shared/save_toggle_feedback.dart';
import '../../domain/entities/player_search_result.dart';

/// A single player row/card in Search Players results and the Saved
/// Players list — shared by both Desktop and Mobile layouts of each.
class PlayerSearchResultCard extends ConsumerWidget {
  const PlayerSearchResultCard({super.key, required this.player});

  final PlayerSearchResult player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      savedPlayersControllerProvider.select(
        (state) => state.value?.any((p) => p.id == player.id) ?? false,
      ),
    );
    final subtitle = [
      player.sport,
      player.position,
    ].where((v) => v != null && v.isNotEmpty).join(' · ');
    final details = [
      if (player.age != null) '${player.age}y',
      if (player.country != null && player.country!.isNotEmpty) player.country,
      if (player.height != null) '${player.height}cm',
      if (player.weight != null) '${player.weight}kg',
    ].join(' · ');

    return Card(
      child: ListTile(
        onTap: () => context.push('/players/${player.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.slate,
          backgroundImage: player.profilePhotoUrl != null
              ? NetworkImage(player.profilePhotoUrl!)
              : null,
          child: player.profilePhotoUrl == null
              ? const Icon(Icons.person, color: AppColors.greyLight)
              : null,
        ),
        title: Text(player.fullName.isEmpty ? 'Unnamed player' : player.fullName),
        subtitle: Text(
          [subtitle, details].where((v) => v.isNotEmpty).join('\n'),
        ),
        isThreeLine: subtitle.isNotEmpty && details.isNotEmpty,
        trailing: IconButton(
          tooltip: saved ? 'Remove from saved' : 'Save player',
          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline),
          onPressed: () => toggleSavedPlayer(context, ref, saved: saved, player: player),
        ),
      ),
    );
  }
}
