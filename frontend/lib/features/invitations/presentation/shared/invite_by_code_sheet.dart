import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/application/player_by_code_provider.dart';
import '../../../player/domain/entities/player_profile.dart';
import 'invite_player_dialog.dart';

/// "Invite by player code" — type `PLY-000123`, see who it belongs to,
/// then invite them.
///
/// The lookup is a deliberate step of its own rather than sending blind on
/// the typed code: a code is six digits with no redundancy, and confirming
/// the name and photo before inviting is the only thing standing between a
/// typo and an invitation to a stranger. The backend accepts either handle,
/// so the send still quotes the code — the lookup is for the human.
Future<void> showInviteByCodeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      // Clears the on-screen keyboard, which otherwise covers the field
      // being typed into.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: const _InviteByCodeSheet(),
    ),
  );
}

class _InviteByCodeSheet extends ConsumerStatefulWidget {
  const _InviteByCodeSheet();

  @override
  ConsumerState<_InviteByCodeSheet> createState() => _InviteByCodeSheetState();
}

class _InviteByCodeSheetState extends ConsumerState<_InviteByCodeSheet> {
  final _controller = TextEditingController();

  /// The code actually submitted, which is not the same as what is in the
  /// field: looking someone up on every keystroke would spend the
  /// backend's tight per-minute lookup budget on prefixes of a code.
  String? _submitted;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.inviteByCodeTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.playerCodeLabel,
              hintText: l10n.playerCodeHint,
              suffixIcon: IconButton(
                tooltip: l10n.inviteByCodeLookUpLabel,
                icon: const Icon(Icons.search),
                onPressed: _submit,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_submitted != null) _Result(code: _submitted!),
        ],
      ),
    );
  }

  void _submit() {
    final code = normalizePublicCode(_controller.text);
    setState(() => _submitted = code.isEmpty ? null : code);
  }
}

class _Result extends ConsumerWidget {
  const _Result({required this.code});

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
          // belonging to a player whose profile is private. Both read as
          // "no such player" on purpose: distinguishing them would turn
          // this into a way to test whether a given code exists.
          error: (error, _) => Text(
            error is AppException && error.statusCode != 404
                ? error.message
                : l10n.playerCodeNotFound,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
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
