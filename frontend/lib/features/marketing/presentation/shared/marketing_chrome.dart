import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/locale/language_toggle_button.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'marketing_nav_items.dart';

/// AppBar actions shared by every Desktop marketing page (Home/About/
/// Pricing/Contact/public listings) — a plain function, not a widget: it
/// contains no layout decision of its own (no breakpoint check), each
/// screen decides where to put the row it returns, same carve-out as
/// AppLogo/BackendStatusIndicator in core/widgets.
List<Widget> marketingDesktopNavActions(BuildContext context, WidgetRef ref) {
  final themeMode = ref.watch(themeModeProvider);
  final l10n = AppLocalizations.of(context)!;
  return [
    for (final item in marketingNavItems(l10n))
      TextButton(
        onPressed: () => context.go(item.path),
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: Text(
          item.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    const SizedBox(width: 8),
    OutlinedButton(
      onPressed: () => context.go('/login'),
      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
      child: Text(
        l10n.authLogIn,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    const SizedBox(width: 8),
    FilledButton(
      onPressed: () => context.go('/register'),
      child: Text(
        l10n.authRegister,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    IconButton(
      tooltip: l10n.themeToggleTooltip,
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
      icon: Icon(themeModeToggleIcon(themeMode)),
    ),
    const LanguageToggleButton(),
    const SizedBox(width: 16),
  ];
}

/// AppBar actions shared by every Mobile marketing page — the theme and
/// language toggles, identical across all six screens that used to define
/// this inline. The nav itself lives in the Drawer (marketingMobileDrawer),
/// not here.
List<Widget> marketingMobileAppBarActions(BuildContext context, WidgetRef ref) {
  final themeMode = ref.watch(themeModeProvider);
  final l10n = AppLocalizations.of(context)!;
  return [
    IconButton(
      tooltip: l10n.themeToggleTooltip,
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
      icon: Icon(themeModeToggleIcon(themeMode)),
    ),
    const LanguageToggleButton(),
  ];
}

/// Wraps the marketing header's AppBar so its layout runs *opposite* the
/// page's ambient locale direction — Arabic pages get a left-to-right
/// header (logo/actions read like LTR) and English pages get a
/// right-to-left header — per product decision to invert the header only,
/// leaving the rest of the page's RTL/LTR behavior untouched.
PreferredSizeWidget marketingHeaderAppBar(
  BuildContext context, {
  required Widget title,
  required List<Widget> actions,
}) {
  final flipped = Directionality.of(context) == TextDirection.rtl
      ? TextDirection.ltr
      : TextDirection.rtl;
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: Directionality(
      textDirection: flipped,
      child: AppBar(title: title, actions: actions),
    ),
  );
}

/// Drawer shared by every Mobile marketing page — same rationale as above.
Widget marketingMobileDrawer(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return Drawer(
    child: ListView(
      children: [
        const DrawerHeader(child: AppLogo(height: 40)),
        for (final item in marketingNavItems(l10n))
          ListTile(
            title: Text(item.label),
            onTap: () {
              Navigator.of(context).pop();
              context.go(item.path);
            },
          ),
        const Divider(),
        ListTile(
          title: Text(l10n.authLogIn),
          onTap: () {
            Navigator.of(context).pop();
            context.go('/login');
          },
        ),
        ListTile(
          title: Text(l10n.authRegister),
          onTap: () {
            Navigator.of(context).pop();
            context.go('/register');
          },
        ),
      ],
    ),
  );
}
