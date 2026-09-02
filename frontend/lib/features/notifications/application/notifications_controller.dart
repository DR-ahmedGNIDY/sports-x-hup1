import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/entities/app_notification.dart';
import '../domain/entities/notifications_page.dart';

/// The unread count behind the badge.
///
/// Watches the session rather than assuming one: signed out it answers 0
/// without a request, and signing in or out re-evaluates it. Without that,
/// a logged-out visitor would fire an authenticated request on every app
/// start, and a badge would survive a logout.
final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  final session = ref.watch(sessionControllerProvider);
  if (session.status != SessionStatus.authenticated) return 0;
  return ref.read(notificationsRepositoryProvider).unreadCount();
});

/// The notifications screen's list — page and unread-filter state, and the
/// resulting page. Same shape as every other paginated controller in the
/// app: applying a filter resets to page 1, [loadPage] keeps the filter.
class NotificationsListController extends AsyncNotifier<NotificationsPage> {
  int _page = 1;
  bool _unreadOnly = false;

  bool get unreadOnly => _unreadOnly;

  @override
  Future<NotificationsPage> build() => _fetch();

  Future<NotificationsPage> _fetch() => ref
      .read(notificationsRepositoryProvider)
      .list(page: _page, unreadOnly: _unreadOnly);

  Future<void> applyUnreadOnly(bool value) async {
    _unreadOnly = value;
    _page = 1;
    await _reload();
  }

  Future<void> loadPage(int page) async {
    _page = page;
    await _reload();
  }

  Future<void> refresh() => _reload();

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Marks one notification read and flips the row in place.
  ///
  /// The row is patched rather than refetched so it does not jump or vanish
  /// under the finger that tapped it — and, under the unread-only filter,
  /// so it stays visible long enough for the tap to also open what it
  /// points at.
  Future<void> markRead(String id) async {
    final current = state.valueOrNull;
    final target = current?.items.where((n) => n.id == id).firstOrNull;
    // Already read: nothing to write, and no count to invalidate.
    if (target == null || target.read) return;

    await ref.read(notificationsRepositoryProvider).markRead(id);
    _patch(id);
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> markAllRead() async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    await _reload();
    ref.invalidate(unreadNotificationsProvider);
  }

  void _patch(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      NotificationsPage(
        items: [
          for (final item in current.items)
            if (item.id == id) _asRead(item) else item,
        ],
        page: current.page,
        pageSize: current.pageSize,
        total: current.total,
      ),
    );
  }

  AppNotification _asRead(AppNotification n) => AppNotification(
    id: n.id,
    type: n.type,
    actor: n.actor,
    entityType: n.entityType,
    entityId: n.entityId,
    read: true,
    createdAt: n.createdAt,
  );
}

final notificationsListProvider =
    AsyncNotifierProvider<NotificationsListController, NotificationsPage>(
      NotificationsListController.new,
    );
