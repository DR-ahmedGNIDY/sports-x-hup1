import '../../../../l10n/generated/app_localizations.dart';
import '../../../store/presentation/widgets/money.dart';
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
      ? switch (notification.actor.role) {
          NotificationActorRole.club => l10n.unnamedClub,
          NotificationActorRole.coach => l10n.coachUnnamed,
          NotificationActorRole.player => l10n.unnamedPlayer,
          NotificationActorRole.customer => l10n.unnamedCustomer,
        }
      : name;

  return switch (notification.type) {
    // A club wrote to a player or a coach; a player or a coach asked to
    // join a club — different sentences, not one with a swapped noun.
    NotificationType.invitationReceived => switch (notification.actor.role) {
      NotificationActorRole.club => l10n.notificationInvitationFromClub(actor),
      NotificationActorRole.coach => l10n.notificationJoinRequestFromCoach(actor),
      NotificationActorRole.player ||
      NotificationActorRole.customer =>
        l10n.notificationJoinRequestFromPlayer(actor),
    },
    NotificationType.invitationAccepted =>
      l10n.notificationInvitationAccepted(actor),
    NotificationType.invitationRejected =>
      l10n.notificationInvitationRejected(actor),
    NotificationType.eventScheduled => _eventScheduledText(l10n, notification, actor),
    NotificationType.subscriptionExpiring => _subscriptionText(
      l10n,
      notification,
      actor,
      expired: false,
    ),
    NotificationType.subscriptionExpired => _subscriptionText(
      l10n,
      notification,
      actor,
      expired: true,
    ),
    NotificationType.subscriptionReminder =>
      l10n.notificationSubscriptionReminder(actor),
    NotificationType.orderPlaced => l10n.notificationOrderPlaced(
      actor,
      notification.order?.number ?? '',
      formatMoney(
        notification.order?.totalMinor ?? 0,
        isArabic: l10n.localeName.startsWith('ar'),
      ),
    ),
  };
}

/// The club's copy names the player (the actor is a player); the player's
/// copy names the club.
String _subscriptionText(
  AppLocalizations l10n,
  AppNotification notification,
  String actor, {
  required bool expired,
}) {
  final date = (notification.subscription?.endDate ?? '').replaceAll('-', '/');
  final toClub = notification.actor.role == NotificationActorRole.player;
  if (toClub) {
    return expired
        ? l10n.notificationSubscriptionExpiredClub(actor, date)
        : l10n.notificationSubscriptionExpiringClub(actor, date);
  }
  return expired
      ? l10n.notificationSubscriptionExpiredPlayer(actor, date)
      : l10n.notificationSubscriptionExpiringPlayer(actor, date);
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
