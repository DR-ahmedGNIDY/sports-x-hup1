import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/admin_repository_impl.dart';
import '../domain/entities/admin_user.dart';

class AdminUsersController extends AsyncNotifier<List<AdminUser>> {
  @override
  Future<List<AdminUser>> build() {
    return ref.read(adminRepositoryProvider).getUsers();
  }

  Future<void> setStatus(String userId, String status) async {
    await ref.read(adminRepositoryProvider).setUserStatus(userId, status);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteUser(String userId) async {
    await ref.read(adminRepositoryProvider).deleteUser(userId);
    final current = state.value ?? const [];
    state = AsyncData(current.where((u) => u.id != userId).toList());
  }
}

final adminUsersControllerProvider =
    AsyncNotifierProvider<AdminUsersController, List<AdminUser>>(
      AdminUsersController.new,
    );
