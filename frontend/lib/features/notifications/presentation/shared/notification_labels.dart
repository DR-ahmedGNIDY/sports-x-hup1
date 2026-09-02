import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/app_notification.dart';

/// Renders a notification's line from its structured parts.
///
/// This is the whole reason the backend stores `type` + `params` instead of
/// a sentence: the wording lives in the same `.arb` files as everything
/// else, so it follows the reader's current language and a copy-edit
/// reaches rows that were written months ago.
String notificationText(AppLocalizations l10n, AppNotification notification) {
  final name = notification.actor.name?.trim();
  final actor = (name == null || name.isEmpty)
      ? (notification.actor.role == NotificationActorRole.club
            ? l10n.unnamedClub
            : l10n.unnamedPlayer)
      : name;

  return switch (notification.type) {
    NotificationType.invitationReceived =>
      notification.actor.role == NotificationActorRole.club
          // A club wrote to a player, and a player asked to join a club —
          // two different sentences, not one with a swapped noun.
          ? l10n.notificationInvitationFromClub(actor)
          : l10n.notificationJoinRequestFromPlayer(actor),
    NotificationType.invitationAccepted =>
      l10n.notificationInvitationAccepted(actor),
    NotificationType.invitationRejected =>
      l10n.notificationInvitationRejected(actor),
  };
}
