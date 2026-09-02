import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/invitations_controller.dart';
import '../../domain/entities/invitation.dart';

/// Accept / Reject / Cancel for one invitation.
///
/// Which buttons appear comes from the server's `canAccept` / `canReject` /
/// `canCancel` — the client never works them out from the status and the
/// direction itself, so there is exactly one implementation of the rules
/// and it is the one that will actually be enforced. A stale `true` here
/// costs a refused request and a SnackBar, never an unauthorised action.
///
/// Reject and cancel ask first. Both are terminal — the state machine has
/// no way back from `REJECTED` or `CANCELLED` — and a mis-tap on a row in a
/// list is exactly the kind of accident a confirmation is for. Accept is
/// terminal too, but it is the affirmative outcome the screen exists to
/// produce, so it does not.
class InvitationActions extends ConsumerStatefulWidget {
  const InvitationActions({
    super.key,
    required this.invitation,
    required this.kind,
  });

  final Invitation invitation;
  final InvitationsListKind kind;

  @override
  ConsumerState<InvitationActions> createState() => _InvitationActionsState();
}

class _InvitationActionsState extends ConsumerState<InvitationActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final invitation = widget.invitation;
    final l10n = AppLocalizations.of(context)!;

    if (!invitation.canAccept && !invitation.canReject && !invitation.canCancel) {
      return const SizedBox.shrink();
    }
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        if (invitation.canReject)
          TextButton(
            onPressed: () => _confirmThen(
              title: l10n.invitationRejectConfirmTitle,
              body: l10n.invitationRejectConfirmBody,
              confirmLabel: l10n.invitationRejectLabel,
              action: (notifier) => notifier.reject(invitation.id),
              feedback: l10n.invitationRejectedFeedback,
            ),
            child: Text(l10n.invitationRejectLabel),
          ),
        if (invitation.canCancel)
          TextButton(
            onPressed: () => _confirmThen(
              title: l10n.invitationCancelConfirmTitle,
              body: l10n.invitationCancelConfirmBody,
              confirmLabel: l10n.invitationCancelInvitationLabel,
              action: (notifier) => notifier.cancel(invitation.id),
              feedback: l10n.invitationCancelledFeedback,
            ),
            child: Text(l10n.invitationCancelInvitationLabel),
          ),
        if (invitation.canAccept)
          FilledButton(
            onPressed: () => _run(
              (notifier) => notifier.accept(invitation.id),
              l10n.invitationAcceptedFeedback,
            ),
            child: Text(l10n.invitationAcceptLabel),
          ),
      ],
    );
  }

  Future<void> _confirmThen({
    required String title,
    required String body,
    required String confirmLabel,
    required Future<Invitation> Function(InvitationsListController) action,
    required String feedback,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(action, feedback);
  }

  Future<void> _run(
    Future<Invitation> Function(InvitationsListController) action,
    String feedback,
  ) async {
    AppHaptics.light();
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(ref.read(invitationsListProvider(widget.kind).notifier));
      messenger.showSnackBar(SnackBar(content: Text(feedback)));
    } on AppException catch (e) {
      // The server refuses anything the state machine no longer allows —
      // an invitation someone else already answered, one that lapsed
      // between render and tap, or a player who joined another club first.
      // Its message is already human-readable, so it is shown as-is.
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
