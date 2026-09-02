import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../club/application/club_by_code_provider.dart';
import '../../../club/domain/entities/club_profile.dart';
import 'code_lookup_sheet.dart';
import 'send_invitation_dialog.dart';

/// "Join by club code" — the mirror of [showInviteByCodeSheet]: type
/// `CLB-000123`, see which club it is, then ask to join.
Future<void> showJoinByCodeSheet(BuildContext context) {
  return showCodeLookupSheet(
    context,
    titleOf: (l10n) => l10n.joinByCodeTitle,
    labelOf: (l10n) => l10n.clubCodeLabel,
    hintOf: (l10n) => l10n.clubCodeHint,
    resultBuilder: (code) => _ClubResult(code: code),
  );
}

class _ClubResult extends ConsumerWidget {
  const _ClubResult({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ref
        .watch(clubByCodeProvider(code))
        .when(
          data: (club) => _ClubResultTile(club: club),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => CodeLookupError(
            message: error is AppException && error.statusCode != 404
                ? error.message
                : l10n.clubCodeNotFound,
          ),
        );
  }
}

class _ClubResultTile extends StatelessWidget {
  const _ClubResultTile({required this.club});

  final ClubProfile club;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final name = club.name?.isNotEmpty == true ? club.name! : l10n.unnamedClub;
    final subtitle = [
      club.city,
      club.country,
    ].where((v) => v != null && v.isNotEmpty).join(', ');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          backgroundImage: club.logoUrl != null
              ? appImageProvider(
                  club.logoUrl!,
                  context: context,
                  decodeWidth: AppImageSize.avatarSmall,
                )
              : null,
          child: club.logoUrl == null
              ? Icon(Icons.shield_outlined, color: colorScheme.onSurfaceVariant)
              : null,
        ),
        title: Text(name),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: FilledButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            final sent = await showRequestToJoinDialog(
              context,
              clubName: name,
              // The id the lookup resolved to, not the typed code — same
              // reason as the invite side.
              clubId: club.id,
            );
            if (!sent) return;
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.joinRequestSentFeedback)),
            );
          },
          child: Text(l10n.requestToJoinLabel),
        ),
      ),
    );
  }
}
