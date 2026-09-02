import '../entities/notifications_page.dart';

/// Throws [AppException] (core/errors) on failure.
///
/// Every method reads or writes the caller's own mailbox — the backend
/// scopes each query to the JWT's user inside the query itself, so there is
/// no id here that could address someone else's notifications.
abstract class NotificationsRepository {
  Future<NotificationsPage> list({int page, bool unreadOnly});

  /// The badge count. Cheap by design; called far more often than [list].
  Future<int> unreadCount();

  Future<void> markRead(String id);

  /// Returns how many were still unread.
  Future<int> markAllRead();
}
