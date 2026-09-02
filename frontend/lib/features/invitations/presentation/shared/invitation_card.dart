import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/invitations_controller.dart';
import '../../domain/entities/invitation.dart';
import 'invitation_actions.dart';
import 'invitation_status_chip.dart';

/// One invitation, from the viewer's side of it.
///
/// The card shows the *counterpart* — a Club's inbox is a list of players,
/// not a list of its own name — which is why the side to render is chosen
/// from [Invitation.type] and [Invitation.direction] rather than from the
/// session's role. That keeps this widget usable unchanged by the Player
/// screens in the next phase.
class InvitationCard extends ConsumerWidget {
  const InvitationCard({super.key, required this.invitation, required this.kind});

  final Invitation invitation;
  final InvitationsListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Whose card this is: a club-to-player invitation is *about* the
    // player whichever end you are looking at it from, and vice versa.
    final showsPlayer = invitation.type == InvitationType.clubToPlayer;
    final player = invitation.player;
    final club = invitation.club;

    final title = showsPlayer
        ? (player?.fullName.isNotEmpty == true ? player!.fullName : l10n.unnamedPlayer)
        : (club?.name?.isNotEmpty == true ? club!.name! : l10n.unnamedClub);
    final subtitle = showsPlayer
        ? [player?.sport, player?.position, player?.country]
              .where((v) => v != null && v.isNotEmpty)
              .join(' · ')
        : [club?.location, club?.level]
              .where((v) => v != null && v.isNotEmpty)
              .join(' · ');
    final code = showsPlayer ? player?.publicCode : club?.publicCode;
    final photoUrl = showsPlayer ? player?.profilePhotoUrl : club?.logoUrl;
    final profilePath = showsPlayer
        ? (player == null ? null : '/players/${player.id}')
        : (club == null ? null : '/clubs/${club.id}');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(url: photoUrl, isClub: !showsPlayer),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      if (code != null)
                        Text(
                          code,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                InvitationStatusChip(status: invitation.status),
              ],
            ),
            if (invitation.message?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.md),
              Text(invitation.message!, style: theme.textTheme.bodyMedium),
            ],
            // Only worth saying while it can still lapse — on a settled
            // invitation the date is noise.
            if (invitation.isPending && invitation.expiresAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.invitationExpiresOn(_formatDate(invitation.expiresAt!)),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (profilePath != null)
                  TextButton(
                    onPressed: () => context.push(profilePath),
                    child: Text(l10n.invitationViewProfileLabel),
                  ),
                const Spacer(),
                InvitationActions(invitation: invitation, kind: kind),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.isClub});

  final String? url;
  final bool isClub;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.surfaceContainerHighest,
      backgroundImage: url != null
          ? appImageProvider(url!, context: context, decodeWidth: AppImageSize.avatarSmall)
          : null,
      child: url == null
          ? Icon(
              isClub ? Icons.shield_outlined : Icons.person,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
