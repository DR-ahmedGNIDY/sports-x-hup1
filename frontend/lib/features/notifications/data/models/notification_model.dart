import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notifications_page.dart';

extension AppNotificationModel on AppNotification {
  /// `null` for a row this build cannot render — an unknown `type` from a
  /// newer backend. Skipping one row beats failing the whole page.
  static AppNotification? fromJson(Map<String, dynamic> json) {
    final type = NotificationType.fromWire(json['type'] as String? ?? '');
    if (type == null) return null;

    final params = json['params'] as Map<String, dynamic>? ?? const {};
    return AppNotification(
      id: json['id'] as String,
      type: type,
      actor: NotificationActor(
        role: NotificationActorRole.fromWire(params['actorRole'] as String?),
        name: params['actorName'] as String?,
        profileId: params['actorProfileId'] as String?,
        publicCode: params['actorPublicCode'] as String?,
      ),
      entityType: NotificationEntityType.fromWire(
        json['entityType'] as String? ?? '',
      ),
      entityId: json['entityId'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt: _dateFrom(json['createdAt']),
    );
  }
}

extension NotificationsPageModel on NotificationsPage {
  static NotificationsPage fromJson(Map<String, dynamic> json) {
    final items = <AppNotification>[
      for (final entry in json['items'] as List<dynamic>? ?? const [])
        ?AppNotificationModel.fromJson(entry as Map<String, dynamic>),
    ];
    return NotificationsPage(
      items: items,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? items.length,
      // The server's total, not `items.length` — a row skipped above is
      // still a row the server counted, and pretending otherwise would
      // break pagination.
      total: json['total'] as int? ?? items.length,
    );
  }
}

DateTime? _dateFrom(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}
