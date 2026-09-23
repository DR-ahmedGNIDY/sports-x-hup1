import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/entities/user_role.dart';
import '../application/admin_stats_controller.dart';
import '../application/admin_users_controller.dart';
import '../domain/entities/admin_user.dart';
import 'suspend_user_dialog.dart';

String _roleLabel(AppLocalizations l10n, UserRole role) => switch (role) {
  UserRole.player => l10n.rolePlayer,
  UserRole.coach => l10n.roleCoach,
  UserRole.club => l10n.roleClub,
  UserRole.admin => l10n.dashboardRoleAdmin,
};

/// "Active", or how long the suspension still has to run. Reads the
/// missing end date as permanent — see [AdminUser.suspendedUntil].
String _statusLabel(AppLocalizations l10n, AdminUser user) {
  if (!user.isSuspended) return l10n.statusActiveLabel;
  if (user.suspendedUntil == null) return l10n.statusSuspendedPermanentLabel;
  final until = user.suspendedUntil!;
  final date = '${until.year}-${until.month.toString().padLeft(2, '0')}'
      '-${until.day.toString().padLeft(2, '0')}';
  return l10n.statusSuspendedUntilLabel(date);
}

/// Desktop only — per the roadmap, admin tooling does not need a mobile
/// layout for V1, so this skips the ResponsiveLayout fork every other
/// screen uses.
///
/// Split into one tab per role — players, coaches, clubs and platform
/// management (admin accounts) — each backed by its own paginated,
/// server-side-filtered [AdminUsersController] instance.
class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.dashboardAdminUsers, style: Theme.of(context).textTheme.headlineSmall),
                TextButton.icon(
                  onPressed: () => context.go('/admin/players-clubs'),
                  icon: const Icon(Icons.groups_outlined),
                  label: Text(l10n.playersClubsNavLabel),
                ),
              ],
            ),
            TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: l10n.adminUsersTabPlayers),
                Tab(text: l10n.adminUsersTabCoaches),
                Tab(text: l10n.adminUsersTabClubs),
                Tab(text: l10n.adminUsersTabPlatform),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _UsersTab(role: UserRole.player),
                  _UsersTab(role: UserRole.coach),
                  _UsersTab(role: UserRole.club),
                  _UsersTab(role: UserRole.admin),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends ConsumerWidget {
  const _UsersTab({required this.role});

  final UserRole role;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, AdminUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteUserTitle),
        content: Text(l10n.deleteUserContent(user.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(adminUsersControllerProvider(role).notifier).deleteUser(user.id);
    }
  }

  Future<void> _suspend(BuildContext context, WidgetRef ref, AdminUser user) async {
    final choice = await showSuspendUserDialog(context, user);
    if (choice == null) return;
    await ref
        .read(adminUsersControllerProvider(role).notifier)
        .suspend(user.id, choice.duration, reason: choice.reason);
    // The counts on the overview page include suspended accounts.
    ref.invalidate(adminStatsProvider);
  }

  Future<void> _reactivate(WidgetRef ref, AdminUser user) async {
    await ref.read(adminUsersControllerProvider(role).notifier).reactivate(user.id);
    ref.invalidate(adminStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final usersAsync = ref.watch(adminUsersControllerProvider(role));

    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(child: Text(l10n.noUsersFound));
        }
        final hasMore = ref.watch(adminUsersControllerProvider(role).notifier).hasMore;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DataTable(
                columns: [
                  DataColumn(label: Text(l10n.emailColumnLabel)),
                  DataColumn(label: Text(l10n.roleColumnLabel)),
                  DataColumn(label: Text(l10n.statusColumnLabel)),
                  DataColumn(label: Text(l10n.moderatorColumnLabel)),
                  DataColumn(label: Text(l10n.actionsColumnLabel)),
                ],
                rows: users
                    .map(
                      (user) => DataRow(
                        cells: [
                          DataCell(Text(user.email)),
                          DataCell(Text(_roleLabel(l10n, user.role))),
                          DataCell(
                            Tooltip(
                              // The admin's own note, if they left
                              // one — worth surfacing here rather
                              // than hiding it behind another click.
                              message: user.suspensionReason ?? '',
                              child: Text(
                                _statusLabel(l10n, user),
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
                                    .read(adminUsersControllerProvider(role).notifier)
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
                                    user.isSuspended ? l10n.activateLabel : l10n.suspendLabel,
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.deleteUserTooltip,
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
                        ref.read(adminUsersControllerProvider(role).notifier).loadMore(),
                    child: Text(l10n.loadMoreLabel),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(adminUsersControllerProvider(role))),
    );
  }
}
