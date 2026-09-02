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
  invitationRejected('INVITATION_REJECTED');

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
  invitation('INVITATION');

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
  player('PLAYER');

  const NotificationActorRole(this.wireValue);

  final String wireValue;

  static NotificationActorRole fromWire(String? value) =>
      value == club.wireValue ? club : player;
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

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actor,
    required this.entityType,
    required this.entityId,
    required this.read,
    this.createdAt,
  });

  final String id;
  final NotificationType type;
  final NotificationActor actor;

  /// What to open when this is tapped.
  final NotificationEntityType? entityType;
  final String entityId;

  final bool read;
  final DateTime? createdAt;
}
