import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../player/domain/entities/player_enums.dart';
import '../application/coach_providers.dart';
import '../domain/coach_models.dart';
import 'shared/coach_cv_view.dart';
import 'shared/coach_widgets.dart';

/// `/coach/preview` — the signed-in coach's CV as others see it, with the
/// owner's controls on top: edit, completion, visibility.
class MyCoachProfilePage extends ConsumerWidget {
  const MyCoachProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(myCoachProfileProvider)
        .when(
          data: (profile) => CoachPageBody(
            onRefresh: () => ref.refresh(myCoachProfileProvider.future),
            children: [
              CoachCvView(
                profile: profile,
                header: _OwnerControls(profile: profile),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            message: error is AppException ? error.message : null,
            onRetry: () => ref.invalidate(myCoachProfileProvider),
          ),
        );
  }
}

class _OwnerControls extends ConsumerWidget {
  const _OwnerControls({required this.profile});

  final CoachProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final percent = profile.completionPercent ?? 0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.coachCvCompletion(percent),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/coach/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.coachEditCv),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: percent / 100),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.visibilityTitle),
              subtitle: Text(
                profile.isPublic
                    ? l10n.coachVisibilityPublicDesc
                    : l10n.coachVisibilityPrivateDesc,
              ),
              value: profile.isPublic,
              onChanged: (isPublic) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(myCoachProfileProvider.notifier)
                      .setVisibility(
                        isPublic
                            ? ProfileVisibility.public
                            : ProfileVisibility.private,
                      );
                } on AppException catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
