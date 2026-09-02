import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/application/player_by_code_provider.dart';
import '../../../player/domain/entities/player_profile.dart';
import 'code_lookup_sheet.dart';
import 'send_invitation_dialog.dart';

/// "Invite by player code" — type `PLY-000123`, see who it belongs to,
/// then invite them. The sheet itself is [showCodeLookupSheet]; this is
/// the player-shaped half of it.
Future<void> showInviteByCodeSheet(BuildContext context) {
  return showCodeLookupSheet(
    context,
    titleOf: (l10n) => l10n.inviteByCodeTitle,
    labelOf: (l10n) => l10n.playerCodeLabel,
    hintOf: (l10n) => l10n.playerCodeHint,
    resultBuilder: (code) => _PlayerResult(code: code),
  );
}

class _PlayerResult extends ConsumerWidget {
  const _PlayerResult({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ref
        .watch(playerByCodeProvider(code))
        .when(
          data: (player) => _PlayerResultTile(player: player),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          // A 404 here is the ordinary case — an unknown code, or one
          // belonging to a player whose profile is private.
          error: (error, _) => CodeLookupError(
            message: error is AppException && error.statusCode != 404
                ? error.message
                : l10n.playerCodeNotFound,
          ),
        );
  }
}

class _PlayerResultTile extends StatelessWidget {
  const _PlayerResultTile({required this.player});

  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final name = player.fullName.isEmpty ? l10n.unnamedPlayer : player.fullName;
    final photoUrl = player.profilePhoto?.secureUrl;
    final subtitle = [
      player.sport,
      player.position,
      player.country,
    ].where((v) => v != null && v.isNotEmpty).join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          backgroundImage: photoUrl != null
              ? appImageProvider(
                  photoUrl,
                  context: context,
                  decodeWidth: AppImageSize.avatarSmall,
                )
              : null,
          child: photoUrl == null
              ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
              : null,
        ),
        title: Text(name),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: FilledButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            final sent = await showInvitePlayerDialog(
              context,
              playerName: name,
              // The code is what was typed, but the id is what the lookup
              // resolved it to — sending the id is what guarantees the
              // invitation lands on the player whose name is on screen.
              // (The backend resolves a code first when given both, so
              // passing both would quietly make the id decorative.)
              playerId: player.id,
            );
            if (!sent) return;
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.invitationSentFeedback)),
            );
          },
          child: Text(l10n.inviteLabel),
        ),
      ),
    );
  }
}
