import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../saved_players/application/saved_players_controller.dart';
import '../../../saved_players/presentation/shared/save_toggle_feedback.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/entities/player_search_result.dart';

/// Bookmark toggle for the Public Player Profile page — visible only to a
/// logged-in Club, same rule as [SimpleContactActions]. Search result
/// cards have their own inline toggle; this is the equivalent for a Club
/// that landed on the full profile directly (a shared link, for example).
class SavePlayerButton extends ConsumerWidget {
  const SavePlayerButton({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClub = ref.watch(sessionControllerProvider).user?.role == UserRole.club;
    if (!isClub) return const SizedBox.shrink();

    final saved = ref.watch(
      savedPlayersControllerProvider.select(
        (state) => state.value?.any((p) => p.id == profile.id) ?? false,
      ),
    );

    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: saved ? l10n.removeSavedTooltip : l10n.savePlayerTooltip,
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline),
      onPressed: () {
        AppHaptics.light();
        toggleSavedPlayer(
        context,
        ref,
        saved: saved,
        player: PlayerSearchResult(
          id: profile.id,
          firstName: profile.firstName,
          lastName: profile.lastName,
          age: _ageFrom(profile.dateOfBirth),
          country: profile.country,
          sport: profile.sport,
          position: profile.position,
          preferredFoot: profile.preferredFoot,
          height: profile.height,
          weight: profile.weight,
          profilePhotoUrl: profile.profilePhoto?.secureUrl,
        ),
        );
      },
    );
  }
}

int? _ageFrom(DateTime? dateOfBirth) {
  if (dateOfBirth == null) return null;
  final now = DateTime.now();
  final days = now.difference(dateOfBirth).inDays;
  return (days / 365.25).floor();
}
