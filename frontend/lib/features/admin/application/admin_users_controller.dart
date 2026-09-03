import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/admin_repository_impl.dart';
import '../domain/entities/admin_user.dart';

class AdminUsersController extends AsyncNotifier<List<AdminUser>> {
  int _page = 1;
  bool hasMore = false;

  @override
  Future<List<AdminUser>> build() async {
    _page = 1;
    final result = await ref.read(adminRepositoryProvider).getUsers(page: _page);
    hasMore = result.hasMore;
    return result.items;
  }

  Future<void> loadMore() async {
    if (!hasMore || state.isLoading) return;
    final nextPage = _page + 1;
    final result = await ref.read(adminRepositoryProvider).getUsers(page: nextPage);
    _page = nextPage;
    hasMore = result.hasMore;
    state = AsyncData([...state.valueOrNull ?? const [], ...result.items]);
  }

  Future<void> setStatus(String userId, String status) async {
    await ref.read(adminRepositoryProvider).setUserStatus(userId, status);
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
    AsyncNotifierProvider<AdminUsersController, List<AdminUser>>(
      AdminUsersController.new,
    );
