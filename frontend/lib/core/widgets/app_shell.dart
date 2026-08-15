import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/club/application/club_profile_controller.dart';
import '../../features/player/application/player_profile_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../locale/language_toggle_button.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_mode_provider.dart';
import '../utils/breakpoints.dart';
import 'app_logo.dart';

/// One entry in the sidebar (Desktop) — role-gated via [roles] (`null` means
/// every role sees it).
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.roles,
  });

  final IconData icon;
  final String Function(AppLocalizations l10n) label;
  final String route;
  final Set<UserRole>? roles;

  bool visibleFor(UserRole? role) => roles == null || (role != null && roles!.contains(role));
}

final List<_NavItem> _navItems = [
  _NavItem(
    icon: Icons.dashboard_outlined,
    label: (l10n) => l10n.dashboardSidebarTitle,
    route: '/dashboard',
  ),
  _NavItem(
    icon: Icons.groups_2_outlined,
    label: (l10n) => l10n.communityNavLabel,
    route: '/community',
  ),
  _NavItem(
    icon: Icons.badge_outlined,
    label: (l10n) => l10n.dashboardMyProfile,
    route: '/player/preview',
    roles: {UserRole.player},
  ),
  _NavItem(
    icon: Icons.edit_outlined,
    label: (l10n) => l10n.dashboardEditProfile,
    route: '/player/edit',
    roles: {UserRole.player},
  ),
  _NavItem(
    icon: Icons.people_outline,
    label: (l10n) => l10n.dashboardAdminUsers,
    route: '/admin/users',
    roles: {UserRole.admin},
  ),
  _NavItem(
    icon: Icons.groups_outlined,
    label: (l10n) => l10n.dashboardAdminPlayersClubs,
    route: '/admin/players-clubs',
    roles: {UserRole.admin},
  ),
  _NavItem(
    icon: Icons.shield_outlined,
    label: (l10n) => l10n.dashboardMyClub,
    route: '/club/preview',
    roles: {UserRole.club},
  ),
  _NavItem(
    icon: Icons.groups_outlined,
    label: (l10n) => l10n.clubPlayersTitle,
    route: '/club/players',
    roles: {UserRole.club},
  ),
  _NavItem(
    icon: Icons.edit_outlined,
    label: (l10n) => l10n.dashboardEditClubProfile,
    route: '/club/edit',
    roles: {UserRole.club},
  ),
  _NavItem(
    icon: Icons.search_outlined,
    label: (l10n) => l10n.dashboardSearchPlayers,
    route: '/search',
    roles: {UserRole.club},
  ),
  _NavItem(
    icon: Icons.bookmark_outline,
    label: (l10n) => l10n.dashboardSavedPlayers,
    route: '/saved-players',
    roles: {UserRole.club},
  ),
  _NavItem(
    icon: Icons.settings_outlined,
    label: (l10n) => l10n.dashboardAccountSettings,
    route: '/settings',
  ),
];

/// Persistent chrome mounted by the `ShellRoute` around every authenticated
/// app page — desktop sidebar + top bar, or mobile top bar + bottom nav.
/// [child] is the routed page's own content, unmodified.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    return AppBreakpoints.isDesktop(context)
        ? _DesktopShell(currentPath: currentPath, child: child)
        : _MobileShell(currentPath: currentPath, child: child);
  }
}

class _DesktopShell extends ConsumerWidget {
  const _DesktopShell({required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final role = ref.watch(sessionControllerProvider).user?.role;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(colorScheme: colorScheme, role: role, currentPath: currentPath),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.colorScheme,
    required this.role,
    required this.currentPath,
  });

  final ColorScheme colorScheme;
  final UserRole? role;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          for (final item in _navItems)
            if (item.visibleFor(role))
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label(l10n)),
                selected: currentPath == item.route,
                onTap: () => context.go(item.route),
              ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const _UserIdentity(),
          const SizedBox(width: AppSpacing.lg),
          IconButton(
            tooltip: l10n.themeToggleTooltip,
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(themeModeToggleIcon(themeMode)),
          ),
          const LanguageToggleButton(),
          IconButton(
            tooltip: l10n.logoutTooltip,
            onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
    );
  }
}

/// Small avatar + first name in the top bar, replacing the raw email text.
/// Sourced from the role-appropriate profile when one is available (Player
/// photo/name, Club logo/name); falls back to the account email — and to
/// an initials avatar — when no profile photo exists yet.
class _UserIdentity extends ConsumerWidget {
  const _UserIdentity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final email = user?.email ?? '';

    String? photoUrl;
    String displayName;
    switch (user?.role) {
      case UserRole.player:
        final profile = ref.watch(playerProfileControllerProvider).value;
        photoUrl = profile?.profilePhoto?.secureUrl;
        displayName = (profile?.firstName?.isNotEmpty ?? false)
            ? profile!.firstName!
            : email;
      case UserRole.club:
        final profile = ref.watch(clubProfileControllerProvider).value;
        photoUrl = profile?.logoUrl;
        displayName = (profile?.name?.isNotEmpty ?? false) ? profile!.name! : email;
      case UserRole.admin:
      case null:
        displayName = email;
    }

    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null ? Text(initial) : null,
        ),
        const SizedBox(width: 10),
        Text(displayName),
      ],
    );
  }
}

class _MobileNavDestination {
  const _MobileNavDestination({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;
}

class _MobileShell extends ConsumerWidget {
  const _MobileShell({required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  // A Player gets two extra tabs (Profile, Skills) next to Home, a Club
  // gets one (Club Players) — Admin keeps the original three. Traits
  // isn't a separate Player tab: it's already shown read-only inside the
  // Profile page (see TraitsSection), so a dedicated bottom-nav slot for
  // it would just be a duplicate.
  List<_MobileNavDestination> _destinationsFor(AppLocalizations l10n, UserRole? role) {
    final home = _MobileNavDestination(
      icon: Icons.home_outlined,
      label: l10n.marketingNavHome,
      route: '/dashboard',
    );
    final community = _MobileNavDestination(
      icon: Icons.groups_2_outlined,
      label: l10n.communityNavLabel,
      route: '/community',
    );
    final settings = _MobileNavDestination(
      icon: Icons.settings_outlined,
      label: l10n.dashboardNavSettings,
      route: '/settings',
    );
    if (role == UserRole.club) {
      // Club Players is the Club's most-used daily tool — same reasoning
      // as the Player's extra tabs below: it belongs in the permanent nav,
      // not buried behind the dashboard.
      return [
        home,
        _MobileNavDestination(
          icon: Icons.groups_outlined,
          label: l10n.clubPlayersTitle,
          route: '/club/players',
        ),
        community,
        settings,
      ];
    }
    if (role != UserRole.player) {
      return [home, community, settings];
    }
    return [
      home,
      _MobileNavDestination(
        icon: Icons.badge_outlined,
        label: l10n.dashboardMyProfile,
        route: '/player/preview',
      ),
      _MobileNavDestination(
        icon: Icons.sports_soccer_outlined,
        label: l10n.skillsSectionTitle,
        route: '/player/skills',
      ),
      community,
      settings,
    ];
  }

  int _indexFor(List<_MobileNavDestination> destinations, String path) {
    final index = destinations.indexWhere(
      (d) => d.route != '/dashboard' && path.startsWith(d.route),
    );
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context)!;
    final role = ref.watch(sessionControllerProvider).user?.role;
    final destinations = _destinationsFor(l10n, role);
    final selectedIndex = _indexFor(destinations, currentPath);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28),
        actions: [
          IconButton(
            tooltip: l10n.themeToggleTooltip,
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(themeModeToggleIcon(themeMode)),
          ),
          const LanguageToggleButton(),
          IconButton(
            tooltip: l10n.logoutTooltip,
            onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(destinations[index].route),
        destinations: [
          for (final d in destinations) NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
