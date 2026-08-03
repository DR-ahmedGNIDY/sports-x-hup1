import 'package:flutter/material.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/backend_status_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Desktop shell: fixed left sidebar + top bar, LinkedIn/Transfermarkt/Linear
/// style dense layout. Feature content is not implemented yet (Phase 0 is
/// foundation only) — this establishes the persistent chrome future phases
/// will render their screens inside of.
class HomePageDesktop extends ConsumerWidget {
  const HomePageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(colorScheme: colorScheme),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  colorScheme: colorScheme,
                  themeMode: themeMode,
                  onToggleTheme: () =>
                      ref.read(themeModeProvider.notifier).toggle(),
                ),
                const Expanded(
                  child: Center(
                    child: Text('Sport X Hub — Desktop foundation ready'),
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
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.colorScheme,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ColorScheme colorScheme;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const BackendStatusIndicator(),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Toggle dark mode',
            onPressed: onToggleTheme,
            icon: Icon(themeModeToggleIcon(themeMode)),
          ),
        ],
      ),
    );
  }
}
