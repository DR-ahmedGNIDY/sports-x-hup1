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
    NotificationType.eventScheduled => _eventScheduledText(l10n, notification, actor),
  };
}

String _eventScheduledText(
  AppLocalizations l10n,
  AppNotification notification,
  String actor,
) {
  final details = notification.event;
  final kind = switch (details?.type) {
    'MATCH' => l10n.calendarEventTypeMatch,
    'TRAINING' => l10n.calendarEventTypeTraining,
    _ => l10n.calendarEventTypeOther,
  };
  final name = details?.name?.trim();
  final event = (name == null || name.isEmpty) ? kind : '$kind — $name';

  final date = details?.date;
  final time = details?.startTime;
  // Rows written before the event details were carried in the payload have
  // neither, and a sentence with blanks in it reads worse than a short one.
  if (date == null || time == null || time.isEmpty) {
    return l10n.notificationEventScheduledShort(actor, event);
  }
  return l10n.notificationEventScheduled(
    actor,
    event,
    '${date.year}/${date.month}/${date.day}',
    time,
  );
}
