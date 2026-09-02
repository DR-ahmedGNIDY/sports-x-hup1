import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/invitation.dart';
import 'invitation_labels.dart';

/// The status badge on an invitation card.
///
/// Colour carries meaning here, so it is never the only thing that does:
/// the chip always shows the translated status word too. Pending is the
/// one state that still wants attention, so it takes the primary colour;
/// accepted is affirmative, and the three closed states share one muted
/// treatment because "rejected", "cancelled" and "expired" are equally
/// over — distinguishing them by colour would imply a difference that does
/// not affect what the viewer can do next.
class InvitationStatusChip extends StatelessWidget {
  const InvitationStatusChip({super.key, required this.status});

  final InvitationStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      InvitationStatus.pending => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      InvitationStatus.accepted => (
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      InvitationStatus.rejected ||
      InvitationStatus.cancelled ||
      InvitationStatus.expired => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        invitationStatusLabel(AppLocalizations.of(context)!, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}
