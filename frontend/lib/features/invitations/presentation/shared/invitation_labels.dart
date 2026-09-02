import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/invitation.dart';

/// Wire value → translated label, in one place so no screen invents its own
/// wording for a status. Mirrors `playerEnumLabels` in the Player feature.
String invitationStatusLabel(AppLocalizations l10n, InvitationStatus status) =>
    switch (status) {
      InvitationStatus.pending => l10n.invitationStatusPending,
      InvitationStatus.accepted => l10n.invitationStatusAccepted,
      InvitationStatus.rejected => l10n.invitationStatusRejected,
      InvitationStatus.cancelled => l10n.invitationStatusCancelled,
      InvitationStatus.expired => l10n.invitationStatusExpired,
    };
