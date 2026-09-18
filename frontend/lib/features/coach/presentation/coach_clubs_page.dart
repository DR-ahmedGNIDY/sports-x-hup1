import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../player/presentation/shared/section_card.dart';
import '../application/coach_providers.dart';
import '../data/coach_repository.dart';
import '../domain/coach_models.dart';
import 'shared/coach_widgets.dart';

/// `/coach/clubs` — every club the coach works for, which one they are
/// acting for now, what each lets them do, and the club↔coach invitations.
class CoachClubsPage extends ConsumerWidget {
  const CoachClubsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final clubs = ref.watch(myCoachClubsProvider);
    final active = ref.watch(activeClubProvider).valueOrNull;

    void refreshAll() {
      ref
        ..invalidate(myCoachClubsProvider)
        ..invalidate(coachInvitationsProvider(true))
        ..invalidate(coachInvitationsProvider(false));
    }

    return CoachPageBody(
      onRefresh: () async {
        refreshAll();
        await ref.read(myCoachClubsProvider.future);
      },
      children: [
        ProfileSectionCard(
          icon: Icons.shield_outlined,
          title: l10n.coachMyClubsTitle,
          child: clubs.when(
            data: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (items.isEmpty)
                  Text(
                    l10n.coachNoClubsYet,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                for (final m in items)
                  _ClubCard(
                    membership: m,
                    isActive: active?.membershipId == m.membershipId,
                    onChanged: refreshAll,
                  ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.group_add_outlined),
                    label: Text(l10n.coachJoinClubByCode),
                    onPressed: () async {
                      final sent = await showCodeInvitationDialog(
                        context,
                        title: l10n.coachJoinClubByCode,
                        codeLabel: l10n.clubCodeLabel,
                        codeHint: 'CLB-000123',
                        submit: (code, message) => ref
                            .read(coachRepositoryProvider)
                            .requestToJoinClub(code, message: message),
                      );
                      if (sent && context.mounted) {
                        refreshAll();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.invitationSentFeedback)),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              message: e is AppException ? e.message : null,
              onRetry: refreshAll,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ProfileSectionCard(
          icon: Icons.mail_outline,
          title: l10n.invitationsTitle,
          child: CoachInvitationsLists(
            viewerIsClub: false,
            onChanged: () => ref.invalidate(myCoachClubsProvider),
          ),
        ),
      ],
    );
  }
}

class _ClubCard extends ConsumerWidget {
  const _ClubCard({
    required this.membership,
    required this.isActive,
    required this.onChanged,
  });

  final CoachClubMembership membership;
  final bool isActive;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final club = membership.club;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: isActive
          ? RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CoachAvatar(
                  url: club?.logoUrl,
                  fallbackIcon: Icons.shield_outlined,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club?.name ?? l10n.coachUnnamedClub,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (club?.location.isNotEmpty ?? false)
                        Text(club!.location, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (isActive)
                  Chip(label: Text(l10n.coachActiveClub))
                else
                  FilledButton(
                    onPressed: () => ref
                        .read(activeClubProvider.notifier)
                        .select(membership),
                    child: Text(l10n.coachSwitchToClub),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.coachYourPermissions, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final p in membership.permissions)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(coachPermissionLabel(l10n, p)),
                  ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              children: [
                if (club != null)
                  TextButton(
                    onPressed: () => context.push('/clubs/${club.id}'),
                    child: Text(l10n.invitationViewProfileLabel),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(l10n.coachLeaveClubConfirm),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text(l10n.cancelLabel),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: Text(l10n.coachLeaveClub),
                          ),
                        ],
                      ),
                    );
                    if (ok != true || !context.mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref
                          .read(coachRepositoryProvider)
                          .leaveClub(membership.membershipId);
                      onChanged();
                    } on AppException catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  },
                  child: Text(l10n.coachLeaveClub),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
