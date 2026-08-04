import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';

class DashboardPageDesktop extends ConsumerWidget {
  const DashboardPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(sessionControllerProvider).user;
    final roleLabel = switch (user?.role) {
      UserRole.club => 'Club',
      UserRole.admin => 'Admin',
      _ => 'Player',
    };

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(colorScheme: colorScheme, role: user?.role),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(user?.email ?? ''),
                      const SizedBox(width: 16),
                      IconButton(
                        tooltip: 'Toggle dark mode',
                        onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                        icon: Icon(themeModeToggleIcon(themeMode)),
                      ),
                      IconButton(
                        tooltip: 'Log out',
                        onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
                        icon: const Icon(Icons.logout_outlined),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('$roleLabel Dashboard — coming in a later phase'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.colorScheme, required this.role});

  final ColorScheme colorScheme;
  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: AppLogo(height: 32),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {},
          ),
          if (role == UserRole.player) ...[
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('My Profile'),
              onTap: () => context.go('/player/preview'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Profile'),
              onTap: () => context.go('/player/edit'),
            ),
          ],
          if (role == UserRole.admin) ...[
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Admin — Users'),
              onTap: () => context.go('/admin/users'),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Admin — Players & Clubs'),
              onTap: () => context.go('/admin/players-clubs'),
            ),
          ],
          if (role == UserRole.club) ...[
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('My Club'),
              onTap: () => context.go('/club/preview'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Club Profile'),
              onTap: () => context.go('/club/edit'),
            ),
            ListTile(
              leading: const Icon(Icons.search_outlined),
              title: const Text('Search Players'),
              onTap: () => context.go('/search'),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Saved Players'),
              onTap: () => context.go('/saved-players'),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Account Settings'),
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }
}
