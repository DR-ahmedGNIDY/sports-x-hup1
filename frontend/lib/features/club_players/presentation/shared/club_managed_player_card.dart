import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/club_players_controller.dart';
import '../../domain/entities/club_managed_player.dart';
import 'club_player_completeness_chip.dart';
import 'whatsapp_send_button.dart';

enum _CardAction { view, edit, resend, remove }

class ClubManagedPlayerCard extends ConsumerWidget {
  const ClubManagedPlayerCard({super.key, required this.player});

  final ClubManagedPlayer player;

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clubPlayerRemoveTitle),
        content: Text(l10n.clubPlayerRemoveContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.clubPlayerRemoveConfirm, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(clubPlayersControllerProvider.notifier).removePlayer(player.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubPlayerRemovedMessage)));
      }
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final profile = player.profile;
    final fullName = profile.fullName.isEmpty ? profile.contact.phone ?? '' : profile.fullName;
    final subtitle = [
      profile.sport,
      profile.position,
    ].where((v) => v != null && v.isNotEmpty).join(' · ');

    return Card(
      child: InkWell(
        onTap: () => context.push('/players/${profile.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: profile.profilePhoto != null
                    ? NetworkImage(profile.profilePhoto!.secureUrl)
                    : null,
                child: profile.profilePhoto == null
                    ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    if (profile.contact.phone != null)
                      Text(
                        profile.contact.phone!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (profile.completionPercent != null) ...[
                      const SizedBox(height: 6),
                      ClubPlayerCompletenessChip(percent: profile.completionPercent),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<_CardAction>(
                onSelected: (action) {
                  switch (action) {
                    case _CardAction.view:
                      context.push('/players/${profile.id}');
                    case _CardAction.edit:
                      context.go('/club/players/${player.userId}/edit');
                    case _CardAction.resend:
                      resendCredentialsAndOpenWhatsApp(context, ref, player);
                    case _CardAction.remove:
                      _confirmRemove(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _CardAction.view,
                    child: Text(l10n.clubPlayerViewAction),
                  ),
                  PopupMenuItem(
                    value: _CardAction.edit,
                    child: Text(l10n.clubPlayerEditAction),
                  ),
                  PopupMenuItem(
                    value: _CardAction.resend,
                    child: Text(l10n.clubPlayerResendCredentialsWhatsAppButton),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: _CardAction.remove,
                    child: Text(
                      l10n.clubPlayerRemoveAction,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
