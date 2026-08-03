import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';

class DashboardPageMobile extends ConsumerStatefulWidget {
  const DashboardPageMobile({super.key});

  @override
  ConsumerState<DashboardPageMobile> createState() => _DashboardPageMobileState();
}

class _DashboardPageMobileState extends ConsumerState<DashboardPageMobile> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(sessionControllerProvider).user;
    final roleLabel = user?.role == UserRole.club ? 'Club' : 'Player';

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28),
        actions: [
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
      body: user?.role == UserRole.player
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$roleLabel Dashboard'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/player/preview'),
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('My Profile'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/player/edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                  ),
                ],
              ),
            )
          : Center(child: Text('$roleLabel Dashboard — coming in a later phase')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) context.go('/settings');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
