import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import 'marketing_nav_items.dart';

/// AppBar actions shared by every Desktop marketing page (Home/About/
/// Pricing/Contact/public listings) — a plain function, not a widget: it
/// contains no layout decision of its own (no breakpoint check), each
/// screen decides where to put the row it returns, same carve-out as
/// AppLogo/BackendStatusIndicator in core/widgets.
List<Widget> marketingDesktopNavActions(BuildContext context, WidgetRef ref) {
  final themeMode = ref.watch(themeModeProvider);
  return [
    for (final item in marketingNavItems)
      TextButton(onPressed: () => context.go(item.path), child: Text(item.label)),
    const SizedBox(width: 8),
    OutlinedButton(onPressed: () => context.go('/login'), child: const Text('Log in')),
    const SizedBox(width: 8),
    FilledButton(onPressed: () => context.go('/register'), child: const Text('Register')),
    IconButton(
      tooltip: 'Toggle dark mode',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
      icon: Icon(themeModeToggleIcon(themeMode)),
    ),
    const SizedBox(width: 16),
  ];
}

/// Drawer shared by every Mobile marketing page — same rationale as above.
Widget marketingMobileDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      children: [
        const DrawerHeader(child: AppLogo(height: 40)),
        for (final item in marketingNavItems)
          ListTile(
            title: Text(item.label),
            onTap: () {
              Navigator.of(context).pop();
              context.go(item.path);
            },
          ),
        const Divider(),
        ListTile(
          title: const Text('Log in'),
          onTap: () {
            Navigator.of(context).pop();
            context.go('/login');
          },
        ),
        ListTile(
          title: const Text('Register'),
          onTap: () {
            Navigator.of(context).pop();
            context.go('/register');
          },
        ),
      ],
    ),
  );
}
