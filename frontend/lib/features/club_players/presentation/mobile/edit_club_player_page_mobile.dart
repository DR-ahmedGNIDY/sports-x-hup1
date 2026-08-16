import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/presentation/mobile/basketball_position_section_mobile.dart';
import '../../../player/presentation/mobile/football_position_section_mobile.dart';
import '../../../player/presentation/shared/profile_details_form.dart';
import '../../../player/presentation/shared/profile_photo_section.dart';
import '../../application/club_players_controller.dart';

/// Mobile "Edit Player" for a Club-managed player — same data/logic as
/// Desktop ([EditClubPlayerPageDesktop]) via the same shared
/// [ProfilePhotoSection]/[ProfileDetailsForm], but a plain stacked
/// [ListView] instead of a single boxed [Card], matching how
/// [AddClubPlayerPageMobile] already diverges from its Desktop
/// counterpart.
class EditClubPlayerPageMobile extends ConsumerWidget {
  const EditClubPlayerPageMobile({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playerAsync = ref.watch(clubManagedPlayerProvider(userId));
    final notifier = ref.read(clubPlayersControllerProvider.notifier);

    return playerAsync.when(
      data: (player) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.clubPlayerEditTitle, style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                onPressed: () => context.go('/club/players'),
                icon: const Icon(Icons.arrow_back_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProfilePhotoSection(
            photoUrl: player.profile.profilePhoto?.secureUrl,
            onUpload: ({required bytes, required filename}) =>
                notifier.uploadPhoto(userId, bytes: bytes, filename: filename),
          ),
          const SizedBox(height: 16),
          ProfileDetailsForm(
            footballPositionEditorBuilder: buildFootballPositionEditorMobile,
            basketballPositionEditorBuilder: buildBasketballPositionEditorMobile,
            initialProfile: player.profile,
            onSave:
                ({
                  firstName,
                  lastName,
                  dateOfBirth,
                  nationality,
                  country,
                  city,
                  sport,
                  position,
                  preferredFoot,
                  height,
                  weight,
                  currentStatus,
                  currentClub,
                  bio,
                  contact,
                }) => notifier.updatePlayer(
                  userId,
                  firstName: firstName,
                  lastName: lastName,
                  dateOfBirth: dateOfBirth,
                  nationality: nationality,
                  country: country,
                  city: city,
                  sport: sport,
                  position: position,
                  preferredFoot: preferredFoot,
                  height: height,
                  weight: weight,
                  currentStatus: currentStatus,
                  currentClub: currentClub,
                  bio: bio,
                  contact: contact,
                ),
            onSaved: () => context.go('/club/players'),
            saveLabel: l10n.saveLabel,
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        onRetry: () => ref.invalidate(clubManagedPlayerProvider(userId)),
      ),
    );
  }
}
