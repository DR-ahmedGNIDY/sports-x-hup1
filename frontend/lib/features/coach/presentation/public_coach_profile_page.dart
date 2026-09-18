import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/entities/user_role.dart';
import '../application/coach_providers.dart';
import '../data/coach_repository.dart';
import '../domain/coach_models.dart';
import 'shared/coach_cv_view.dart';
import 'shared/coach_widgets.dart';

/// `/coaches/:id` (shareable, no session needed) and its in-shell twin
/// `/search/coaches/:id`. A club reading it gets an "Invite to my club"
/// action.
class PublicCoachProfilePage extends ConsumerWidget {
  const PublicCoachProfilePage({super.key, required this.coachId});

  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final role = ref.watch(
      sessionControllerProvider.select((s) => s.user?.role),
    );
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(l10n.coachProfileTitle),
      ),
      body: ref
          .watch(publicCoachProfileProvider(coachId))
          .when(
            data: (profile) => CoachPageBody(
              children: [
                CoachCvView(
                  profile: profile,
                  header: role == UserRole.club
                      ? _InviteButton(profile: profile)
                      : null,
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(
              message: error is AppException && error.statusCode == 404
                  ? l10n.coachNotFound
                  : null,
              onRetry: () =>
                  ref.invalidate(publicCoachProfileProvider(coachId)),
            ),
          ),
    );
  }
}

class _InviteButton extends ConsumerWidget {
  const _InviteButton({required this.profile});

  final CoachProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final code = profile.publicCode;
    if (code == null) return const SizedBox.shrink();
    return FilledButton.icon(
      icon: const Icon(Icons.person_add_alt),
      label: Text(l10n.coachInviteToClub),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref.read(coachRepositoryProvider).inviteCoach(code);
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.invitationSentFeedback)),
          );
        } on AppException catch (e) {
          messenger.showSnackBar(SnackBar(content: Text(e.message)));
        }
      },
    );
  }
}
