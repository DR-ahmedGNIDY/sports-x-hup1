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
    final roleLabel = user?.role == UserRole.club ? 'Club' : 'Player';

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(colorScheme: colorScheme),
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
  const _Sidebar({required this.colorScheme});

  final ColorScheme colorScheme;

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
