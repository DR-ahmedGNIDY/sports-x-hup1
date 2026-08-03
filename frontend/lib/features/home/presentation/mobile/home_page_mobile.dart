import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/backend_status_indicator.dart';

/// Mobile shell: native-app feel with a bottom navigation bar, matching the
/// roadmap's "native application" mobile design direction — this is not a
/// shrunk version of [HomePageDesktop].
class HomePageMobile extends ConsumerStatefulWidget {
  const HomePageMobile({super.key});

  @override
  ConsumerState<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends ConsumerState<HomePageMobile> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28),
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Sport X Hub — Mobile foundation ready'),
            SizedBox(height: 12),
            BackendStatusIndicator(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
