import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../saved_players/application/saved_players_controller.dart';
import '../../../saved_players/presentation/shared/save_toggle_feedback.dart';
import '../../domain/entities/player_search_result.dart';

/// A single player row/card in Search Players results (both the
/// authenticated Club tool at /search and the public listing at /players)
/// and the Saved Players list — shared by both Desktop and Mobile layouts
/// of each.
class PlayerSearchResultCard extends ConsumerWidget {
  const PlayerSearchResultCard({super.key, required this.player});

  final PlayerSearchResult player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isClub = ref.watch(sessionControllerProvider).user?.role == UserRole.club;
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

    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: () => context.push('/players/${player.id}'),
        leading: CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          backgroundImage: player.profilePhotoUrl != null
              ? appImageProvider(player.profilePhotoUrl!, context: context, decodeWidth: AppImageSize.avatarSmall)
              : null,
          child: player.profilePhotoUrl == null
              ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
              : null,
        ),
        title: Text(player.fullName.isEmpty ? l10n.unnamedPlayer : player.fullName),
        subtitle: Text(
          [subtitle, details].where((v) => v.isNotEmpty).join('\n'),
        ),
        isThreeLine: subtitle.isNotEmpty && details.isNotEmpty,
        trailing: isClub
            ? IconButton(
                tooltip: saved ? l10n.removeSavedTooltip : l10n.savePlayerTooltip,
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline),
                onPressed: () => toggleSavedPlayer(context, ref, saved: saved, player: player),
              )
            : null,
      ),
    );
  }
}
