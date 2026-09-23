import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_state.dart';
import '../application/admin_stats_controller.dart';
import '../application/admin_users_controller.dart';
import '../domain/entities/admin_user.dart';
import 'suspend_user_dialog.dart';

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

  Future<void> _suspend(BuildContext context, WidgetRef ref, AdminUser user) async {
    final choice = await showSuspendUserDialog(context, user);
    if (choice == null) return;
    await ref
        .read(adminUsersControllerProvider.notifier)
        .suspend(user.id, choice.duration, reason: choice.reason);
    // The counts on the overview page include suspended accounts.
    ref.invalidate(adminStatsProvider);
  }

  Future<void> _reactivate(WidgetRef ref, AdminUser user) async {
    await ref.read(adminUsersControllerProvider.notifier).reactivate(user.id);
    ref.invalidate(adminStatsProvider);
  }

  /// "Active", or how long the suspension still has to run. Reads the
  /// missing end date as permanent — see [AdminUser.suspendedUntil].
  static String _statusLabel(AdminUser user) {
    if (!user.isSuspended) return 'ACTIVE';
    if (user.suspendedUntil == null) return 'SUSPENDED · permanent';
    final until = user.suspendedUntil!;
    final date = '${until.year}-${until.month.toString().padLeft(2, '0')}'
        '-${until.day.toString().padLeft(2, '0')}';
    return 'SUSPENDED · until $date';
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
                          DataColumn(label: Text('Moderator')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: users
                            .map(
                              (user) => DataRow(
                                cells: [
                                  DataCell(Text(user.email)),
                                  DataCell(Text(user.role.wireValue)),
                                  DataCell(
                                    Tooltip(
                                      // The admin's own note, if they left
                                      // one — worth surfacing here rather
                                      // than hiding it behind another click.
                                      message: user.suspensionReason ?? '',
                                      child: Text(
                                        _statusLabel(user),
                                        style: TextStyle(
                                          color: user.isSuspended
                                              ? AppColors.error
                                              : AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Switch(
                                      value: user.isModerator,
                                      onChanged: (value) async {
                                        await ref
                                            .read(adminUsersControllerProvider.notifier)
                                            .setModerator(user.id, value);
                                        ref.invalidate(adminStatsProvider);
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () => user.isSuspended
                                              ? _reactivate(ref, user)
                                              : _suspend(context, ref, user),
                                          child: Text(
                                            user.isSuspended ? 'Activate' : 'Suspend',
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
