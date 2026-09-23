import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/entities/user_role.dart';
import '../data/repositories/admin_repository_impl.dart';
import '../domain/entities/admin_user.dart';

/// One instance per role tab (Players / Coaches / Clubs / Platform
/// management), each with its own page and "load more" state — mirrors
/// `InvitationsListController`.
class AdminUsersController extends FamilyAsyncNotifier<List<AdminUser>, UserRole> {
  int _page = 1;
  bool hasMore = false;

  @override
  Future<List<AdminUser>> build(UserRole arg) async {
    _page = 1;
    final result = await ref
        .read(adminRepositoryProvider)
        .getUsers(page: _page, role: arg);
    hasMore = result.hasMore;
    return result.items;
  }

  Future<void> loadMore() async {
    if (!hasMore || state.isLoading) return;
    final nextPage = _page + 1;
    final result = await ref
        .read(adminRepositoryProvider)
        .getUsers(page: nextPage, role: arg);
    _page = nextPage;
    hasMore = result.hasMore;
    state = AsyncData([...state.valueOrNull ?? const [], ...result.items]);
  }

  Future<void> setStatus(String userId, String status) async {
    await ref.read(adminRepositoryProvider).setUserStatus(userId, status);
    ref.invalidateSelf();
    await future;
  }

  /// Suspends for a fixed term, or forever. Re-reads the list afterwards
  /// because the row now has to show the end date the server computed.
  Future<void> suspend(
    String userId,
    SuspensionDuration duration, {
    String? reason,
  }) async {
    await ref
        .read(adminRepositoryProvider)
        .suspendUser(userId, duration, reason: reason);
    ref.invalidateSelf();
    await future;
  }

  Future<void> reactivate(String userId) async {
    await ref.read(adminRepositoryProvider).reactivateUser(userId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> setModerator(String userId, bool isModerator) async {
    await ref.read(adminRepositoryProvider).setUserModerator(userId, isModerator);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteUser(String userId) async {
    await ref.read(adminRepositoryProvider).deleteUser(userId);
    final current = state.valueOrNull ?? const [];
    state = AsyncData(current.where((u) => u.id != userId).toList());
  }
}

final adminUsersControllerProvider =
    AsyncNotifierProvider.family<AdminUsersController, List<AdminUser>, UserRole>(
      AdminUsersController.new,
    );
