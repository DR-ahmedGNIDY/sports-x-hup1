import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/invitations_controller.dart';
import '../../domain/entities/invitation.dart';

/// Matches `INVITATION_MESSAGE_MAX_LENGTH` on the backend. Enforced here as
/// a counter and a hard limit rather than left to the server, so the length
/// rule is visible while typing instead of arriving as a rejection after
/// composing 600 characters.
const int invitationMessageMaxLength = 500;

/// Composes and sends a CLUB_TO_PLAYER invitation. Returns `true` once one
/// has actually been created — callers use that to show their own
/// confirmation, or to leave the screen.
///
/// The player is addressed by whichever handle the caller has: an id when
/// the invite starts from a profile already on screen, a code when it
/// starts from someone typing one. Both are passed straight through to the
/// backend, which accepts either.
Future<bool> showInvitePlayerDialog(
  BuildContext context, {
  required String playerName,
  String? playerId,
  String? playerCode,
}) {
  return _show(
    context,
    titleOf: (l10n) => l10n.invitePlayerTitle,
    bodyOf: (l10n) => l10n.invitePlayerBody(playerName),
    send: (actions, message) => actions.invitePlayer(
      playerId: playerId,
      playerCode: playerCode,
      message: message,
    ),
  );
}

/// The mirror image: a Player asking to join a club (PLAYER_TO_CLUB).
///
/// Same dialog, different endpoint and wording. The two are one widget
/// because the composing step is genuinely identical — a note and a send —
/// and two copies would be two places for the message limit to drift.
Future<bool> showRequestToJoinDialog(
  BuildContext context, {
  required String clubName,
  String? clubId,
  String? clubCode,
}) {
  return _show(
    context,
    titleOf: (l10n) => l10n.requestToJoinTitle,
    bodyOf: (l10n) => l10n.requestToJoinBody(clubName),
    send: (actions, message) => actions.requestToJoinClub(
      clubId: clubId,
      clubCode: clubCode,
      message: message,
    ),
  );
}

typedef _Send =
    Future<Invitation> Function(InvitationsActions actions, String message);

Future<bool> _show(
  BuildContext context, {
  required String Function(AppLocalizations) titleOf,
  required String Function(AppLocalizations) bodyOf,
  required _Send send,
}) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (context) =>
        _SendInvitationDialog(titleOf: titleOf, bodyOf: bodyOf, send: send),
  );
  return sent ?? false;
}

class _SendInvitationDialog extends ConsumerStatefulWidget {
  const _SendInvitationDialog({
    required this.titleOf,
    required this.bodyOf,
    required this.send,
  });

  final String Function(AppLocalizations) titleOf;
  final String Function(AppLocalizations) bodyOf;
  final _Send send;

  @override
  ConsumerState<_SendInvitationDialog> createState() =>
      _SendInvitationDialogState();
}

class _SendInvitationDialogState extends ConsumerState<_SendInvitationDialog> {
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.titleOf(l10n)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.bodyOf(l10n),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _messageController,
            enabled: !_sending,
            maxLength: invitationMessageMaxLength,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: l10n.invitationMessageLabel,
              hintText: l10n.invitationMessageHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.sendLabel),
        ),
      ],
    );
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.send(
        ref.read(invitationsActionsProvider),
        _messageController.text.trim(),
      );
      AppHaptics.success();
      navigator.pop(true);
    } on AppException catch (e) {
      // Everything the business rules refuse arrives here already worded:
      // a pending invitation already exists for this pair, the player is
      // in a club, or the account belongs to a club that created it. The
      // dialog stays open so the message can be edited and retried.
      AppHaptics.error();
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      if (mounted) setState(() => _sending = false);
    }
  }
}
