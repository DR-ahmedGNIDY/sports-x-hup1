import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../player/domain/entities/player_search_result.dart';
import '../../application/saved_players_controller.dart';

/// Toggles the saved state for [player] and surfaces a SnackBar on
/// failure (e.g. a double-tap racing a save that already landed). Shared
/// by every save/unsave control — search result cards and the public
/// profile page — so this error handling isn't duplicated per widget.
Future<void> toggleSavedPlayer(
  BuildContext context,
  WidgetRef ref, {
  required bool saved,
  required PlayerSearchResult player,
}) async {
  final notifier = ref.read(savedPlayersControllerProvider.notifier);
  try {
    if (saved) {
      await notifier.unsave(player.id);
    } else {
      await notifier.save(player);
    }
  } on AppException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
