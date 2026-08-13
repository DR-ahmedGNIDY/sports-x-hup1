import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_state.dart';
import '../application/admin_users_controller.dart';
import '../domain/entities/admin_user.dart';

/// Desktop only — per the roadmap, admin tooling does not need a mobile
/// layout for V1, so this skips the ResponsiveLayout fork every other
/// screen uses.
class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('This permanently deletes ${user.email}. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(adminUsersControllerProvider.notifier).deleteUser(user.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersControllerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Admin — Users', style: Theme.of(context).textTheme.headlineSmall),
              TextButton.icon(
                onPressed: () => context.go('/admin/players-clubs'),
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Players & Clubs'),
              ),
            ],
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                final hasMore = ref.watch(adminUsersControllerProvider.notifier).hasMore;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: users
                            .map(
                              (user) => DataRow(
                                cells: [
                                  DataCell(Text(user.email)),
                                  DataCell(Text(user.role.wireValue)),
                                  DataCell(
                                    Text(
                                      user.status,
                                      style: TextStyle(
                                        color: user.status == 'SUSPENDED'
                                            ? AppColors.error
                                            : AppColors.success,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () => ref
                                              .read(adminUsersControllerProvider.notifier)
                                              .setStatus(
                                                user.id,
                                                user.status == 'SUSPENDED'
                                                    ? 'ACTIVE'
                                                    : 'SUSPENDED',
                                              ),
                                          child: Text(
                                            user.status == 'SUSPENDED'
                                                ? 'Activate'
                                                : 'Suspend',
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete user',
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () => _confirmDelete(context, ref, user),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                      if (hasMore)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: OutlinedButton(
                            onPressed: () =>
                                ref.read(adminUsersControllerProvider.notifier).loadMore(),
                            child: const Text('Load more'),
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  ErrorState(onRetry: () => ref.invalidate(adminUsersControllerProvider)),
            ),
          ),
        ],
      ),
    );
  }
}
