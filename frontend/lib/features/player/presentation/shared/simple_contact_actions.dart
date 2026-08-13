import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../application/player_contact_provider.dart';

/// Phase 3 Simple Contact — WhatsApp/Email/Phone action buttons, visible
/// only to a logged-in Club. Renders nothing for a Player viewer or a
/// signed-out visitor; the backend enforces the same rule independently
/// (GET /players/:id/contact is CLUB-only), this just avoids the
/// unnecessary request and UI clutter for everyone else.
class SimpleContactActions extends ConsumerWidget {
  const SimpleContactActions({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClub = ref.watch(sessionControllerProvider).user?.role == UserRole.club;
    if (!isClub) return const SizedBox.shrink();

    final contactAsync = ref.watch(playerContactProvider(playerId));
    final l10n = AppLocalizations.of(context)!;

    return contactAsync.when(
      data: (contact) {
        if (contact.phone == null && contact.email == null && contact.whatsapp == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.contactSectionTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (contact.whatsapp != null)
                    FilledButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://wa.me/${_digitsOnly(contact.whatsapp!)}'),
                      ),
                      icon: const Icon(Icons.chat_outlined),
                      label: Text(l10n.contactWhatsappButton),
                    ),
                  if (contact.email != null)
                    OutlinedButton.icon(
                      onPressed: () =>
                          launchUrl(Uri.parse('mailto:${contact.email}')),
                      icon: const Icon(Icons.email_outlined),
                      label: Text(l10n.contactEmailButton),
                    ),
                  if (contact.phone != null)
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('tel:${contact.phone}')),
                      icon: const Icon(Icons.phone_outlined),
                      label: Text(l10n.contactCallButton),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 24),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');
