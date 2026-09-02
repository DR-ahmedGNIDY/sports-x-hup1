import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../club/domain/entities/club_profile.dart';
import 'send_invitation_dialog.dart';

/// "Request to join" on a public club profile — visible only to a
/// logged-in Player, the mirror of [InvitePlayerButton]'s club-only rule.
///
/// Optimistic about eligibility for the same reason: whether the player is
/// already in a club, already has a pending conversation with this one, or
/// holds a club-created account are all things the send itself reports,
/// and pre-checking them would cost requests on every profile view to
/// pre-empt a message that arrives anyway.
class RequestToJoinButton extends ConsumerWidget {
  const RequestToJoinButton({super.key, required this.club, this.compact = false});

  final ClubProfile club;

  /// Icon-only, for an app bar with no room for a label.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlayer = ref.watch(sessionControllerProvider).user?.role == UserRole.player;
    if (!isPlayer) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final name = club.name?.isNotEmpty == true ? club.name! : l10n.unnamedClub;

    Future<void> request() async {
      final sent = await showRequestToJoinDialog(
        context,
        clubName: name,
        clubId: club.id,
      );
      if (sent && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.joinRequestSentFeedback)));
      }
    }

    if (compact) {
      return IconButton(
        tooltip: l10n.requestToJoinLabel,
        onPressed: request,
        icon: const Icon(Icons.person_add_alt_outlined),
      );
    }
    return FilledButton.icon(
      onPressed: request,
      icon: const Icon(Icons.person_add_alt_outlined),
      label: Text(l10n.requestToJoinLabel),
    );
  }
}
