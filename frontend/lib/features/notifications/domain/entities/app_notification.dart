/// The notification domain, mirroring `toNotificationView` on the backend
/// (`backend/src/notifications/notifications.mapper.ts`).
///
/// Nothing here carries rendered text. The server stores a [type] and a
/// small [NotificationActor], and the wording is produced on the client
/// from the app's own `.arb` files — so a reader who switches language
/// sees their whole history in the new one, and a copy-edit reaches
/// everything ever sent. See the schema's comment on the backend for why
/// the alternative was rejected.
library;

enum NotificationType {
  invitationReceived('INVITATION_RECEIVED'),
  invitationAccepted('INVITATION_ACCEPTED'),
  invitationRejected('INVITATION_REJECTED'),
  eventScheduled('EVENT_SCHEDULED'),
  orderPlaced('ORDER_PLACED'),
  subscriptionExpiring('SUBSCRIPTION_EXPIRING'),
  subscriptionExpired('SUBSCRIPTION_EXPIRED'),
  subscriptionReminder('SUBSCRIPTION_REMINDER');

  const NotificationType(this.wireValue);

  final String wireValue;

  /// Unknown values answer `null` rather than throwing: a backend that
  /// learns a new notification type must not crash a client that predates
  /// it. Rows it cannot render are skipped.
  static NotificationType? fromWire(String value) {
    for (final type in NotificationType.values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }
}

enum NotificationEntityType {
  invitation('INVITATION'),
  coachInvitation('COACH_INVITATION'),
  calendarEvent('CALENDAR_EVENT'),
  storeOrder('STORE_ORDER'),
  playerSubscription('PLAYER_SUBSCRIPTION');

  const NotificationEntityType(this.wireValue);

  final String wireValue;

  static NotificationEntityType? fromWire(String value) {
    for (final type in NotificationEntityType.values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }
}

enum NotificationActorRole {
  club('CLUB'),
  player('PLAYER'),
  coach('COACH'),
  customer('CUSTOMER');

  const NotificationActorRole(this.wireValue);

  final String wireValue;

  static NotificationActorRole fromWire(String? value) => switch (value) {
    'CLUB' => club,
    'COACH' => coach,
    'CUSTOMER' => customer,
    _ => player,
  };
}

/// The other party — who did the thing being announced.
///
/// Deliberately free of contact details: the backend builds this from the
/// same summary a public profile already shows, so a notification can never
/// become a way to read a phone number that `GET /players/:id/contact`
/// guards.
class NotificationActor {
  const NotificationActor({
    required this.role,
    this.name,
    this.profileId,
    this.publicCode,
  });

  final NotificationActorRole role;
  final String? name;
  final String? profileId;
  final String? publicCode;
}

/// What a calendar-event notification says beyond who sent it: the kind of
/// session, when it starts, and (a match's opponent or a custom activity's
/// name) what it is called.
class NotificationEventDetails {
  const NotificationEventDetails({this.name, this.type, this.date, this.startTime});

  final String? name;
  final String? type;
  final DateTime? date;
  final String? startTime;
}

/// What an order notification tells an admin before they open it.
class NotificationOrderDetails {
  const NotificationOrderDetails({this.number, this.totalMinor});

  final String? number;
  final int? totalMinor;
}

/// What a subscription notification says: when it ends, and — on the
/// club's copy — which player, so the tap can open their reminder options.
class NotificationSubscriptionDetails {
  const NotificationSubscriptionDetails({this.endDate, this.playerUserId});

  /// 'YYYY-MM-DD'.
  final String? endDate;
  final String? playerUserId;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actor,
    required this.entityType,
    required this.entityId,
    required this.read,
    this.createdAt,
    this.event,
    this.order,
    this.subscription,
  });

  final String id;
  final NotificationType type;
  final NotificationActor actor;
  final NotificationEventDetails? event;

  /// Store orders only.
  final NotificationOrderDetails? order;

  /// Subscriptions only.
  final NotificationSubscriptionDetails? subscription;

  /// What to open when this is tapped.
  final NotificationEntityType? entityType;
  final String entityId;

  final bool read;
  final DateTime? createdAt;
}
