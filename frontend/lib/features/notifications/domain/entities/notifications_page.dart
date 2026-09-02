import 'app_notification.dart';

/// One page of `GET /notifications` — the project's standard page-based
/// envelope, same shape and page size as every other paginated list.
class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<AppNotification> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasNextPage => page * pageSize < total;

  static const empty = NotificationsPage(items: [], page: 1, pageSize: 20, total: 0);
}
