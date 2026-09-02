import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../player/domain/entities/player_profile.dart';
import 'invite_player_dialog.dart';

/// "Invite to club" on a public player profile — visible only to a
/// logged-in Club, the same rule [SavePlayerButton] and
/// [SimpleContactActions] follow.
///
/// It is deliberately optimistic about eligibility: the button shows for
/// every player a Club can see, and the reasons an invitation might be
/// refused (an invitation is already pending, the player is already in a
/// club, the account was created by a club) are reported by the server
/// when it is sent. Working them out here would mean three extra requests
/// per profile view to pre-empt a message the send already produces — and
/// a client-side "you can't" that the server disagreed with would be worse
/// than either.
class InvitePlayerButton extends ConsumerWidget {
  const InvitePlayerButton({super.key, required this.profile, this.compact = false});

  final PlayerProfile profile;

  /// Icon-only, for an app bar with no room for a label.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClub = ref.watch(sessionControllerProvider).user?.role == UserRole.club;
    if (!isClub) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final name = profile.fullName.isEmpty ? l10n.unnamedPlayer : profile.fullName;

    Future<void> invite() async {
      final sent = await showInvitePlayerDialog(
        context,
        playerName: name,
        playerId: profile.id,
      );
      if (sent && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.invitationSentFeedback)));
      }
    }

    if (compact) {
      return IconButton(
        tooltip: l10n.invitePlayerLabel,
        onPressed: invite,
        icon: const Icon(Icons.group_add_outlined),
      );
    }
    return FilledButton.icon(
      onPressed: invite,
      icon: const Icon(Icons.group_add_outlined),
      label: Text(l10n.invitePlayerLabel),
    );
  }
}
