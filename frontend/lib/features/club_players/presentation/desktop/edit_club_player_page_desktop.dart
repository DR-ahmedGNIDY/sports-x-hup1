import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/presentation/desktop/basketball_position_section_desktop.dart';
import '../../../player/presentation/desktop/football_position_section_desktop.dart';
import '../../../player/presentation/shared/profile_details_form.dart';
import '../../../player/presentation/shared/profile_photo_section.dart';
import '../../application/club_players_controller.dart';

/// Desktop "Edit Player" for a Club-managed player — a trimmed-down
/// counterpart of [EditProfilePageDesktop] (photo + the identity/sports/
/// bio/contact form only; no achievements/media/social-links/visibility,
/// which stay the player's own to manage), reusing the exact same
/// [ProfilePhotoSection]/[ProfileDetailsForm] widgets bound to this
/// specific managed player instead of the signed-in Player's own profile.
class EditClubPlayerPageDesktop extends ConsumerWidget {
  const EditClubPlayerPageDesktop({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playerAsync = ref.watch(clubManagedPlayerProvider(userId));
    final actions = ref.read(clubPlayersActionsProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.clubPlayerEditTitle, style: Theme.of(context).textTheme.headlineSmall),
                  TextButton.icon(
                    onPressed: () => context.go('/club/players'),
                    icon: const Icon(Icons.arrow_back_outlined),
                    label: Text(l10n.backLabel),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              playerAsync.when(
                data: (player) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfilePhotoSection(
                          photoUrl: player.profile.profilePhoto?.secureUrl,
                          onUpload: ({required bytes, required filename}) =>
                              actions.uploadPhoto(userId, bytes: bytes, filename: filename),
                        ),
                        const SizedBox(height: 24),
                        Divider(color: Theme.of(context).colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        ProfileDetailsForm(
                          footballPositionEditorBuilder: buildFootballPositionEditorDesktop,
                          basketballPositionEditorBuilder: buildBasketballPositionEditorDesktop,
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
                              }) => actions.updatePlayer(
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
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(
                  onRetry: () => ref.invalidate(clubManagedPlayerProvider(userId)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
