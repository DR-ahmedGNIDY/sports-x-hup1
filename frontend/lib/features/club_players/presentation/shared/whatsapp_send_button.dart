import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../club/application/club_profile_controller.dart';
import '../../application/club_players_controller.dart';
import '../../domain/entities/club_managed_player.dart';
import '../../domain/entities/club_player_credentials.dart';

String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

String _credentialsMessage({
  required AppLocalizations l10n,
  required String firstName,
  required String clubName,
  required ClubPlayerCredentials credentials,
}) {
  return l10n.clubPlayerCredentialsWhatsAppMessage(
    firstName,
    clubName,
    credentials.username,
    credentials.password,
  );
}

Future<void> _openWhatsApp({
  required String phone,
  required String message,
}) {
  final uri = Uri.parse(
    'https://wa.me/${_digitsOnly(phone)}?text=${Uri.encodeComponent(message)}',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Issues a fresh password for [player] (invalidating any earlier one —
/// there's no plaintext password on hand outside the create response) and
/// opens WhatsApp with it. Shared by [ResendCredentialsWhatsAppButton] and
/// the roster card's overflow-menu "Resend credentials" action, so both
/// entry points go through the identical flow.
Future<void> resendCredentialsAndOpenWhatsApp(
  BuildContext context,
  WidgetRef ref,
  ClubManagedPlayer player,
) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final credentials = await ref
        .read(clubPlayersControllerProvider.notifier)
        .resendCredentials(player.userId);
    if (!context.mounted) return;
    final clubName = ref.read(clubProfileControllerProvider).value?.name ?? '';
    await _openWhatsApp(
      phone: credentials.username,
      message: _credentialsMessage(
        l10n: l10n,
        firstName: player.profile.firstName ?? '',
        clubName: clubName,
        credentials: credentials,
      ),
    );
  } on AppException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Right after a player is created, the create response already carries
/// the one-time plaintext password — this opens WhatsApp with it directly,
/// no extra request needed.
class SendCredentialsWhatsAppButton extends ConsumerWidget {
  const SendCredentialsWhatsAppButton({
    super.key,
    required this.firstName,
    required this.credentials,
  });

  final String firstName;
  final ClubPlayerCredentials credentials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final clubName = ref.watch(clubProfileControllerProvider).value?.name ?? '';
    return FilledButton.icon(
      onPressed: () => _openWhatsApp(
        phone: credentials.username,
        message: _credentialsMessage(
          l10n: l10n,
          firstName: firstName,
          clubName: clubName,
          credentials: credentials,
        ),
      ),
      icon: const Icon(Icons.chat_outlined),
      label: Text(l10n.clubPlayerSendWhatsAppButton),
    );
  }
}

/// From the roster list, there's no plaintext password on hand (it was
/// only ever returned once, at creation) — so this issues a fresh one
/// first (invalidating the old one) and then opens WhatsApp with it.
class ResendCredentialsWhatsAppButton extends ConsumerStatefulWidget {
  const ResendCredentialsWhatsAppButton({super.key, required this.player});

  final ClubManagedPlayer player;

  @override
  ConsumerState<ResendCredentialsWhatsAppButton> createState() =>
      _ResendCredentialsWhatsAppButtonState();
}

class _ResendCredentialsWhatsAppButtonState
    extends ConsumerState<ResendCredentialsWhatsAppButton> {
  bool _sending = false;

  Future<void> _resendAndSend() async {
    setState(() => _sending = true);
    await resendCredentialsAndOpenWhatsApp(context, ref, widget.player);
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: _sending ? null : _resendAndSend,
      icon: _sending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_outlined),
      label: Text(l10n.clubPlayerResendCredentialsWhatsAppButton),
    );
  }
}
