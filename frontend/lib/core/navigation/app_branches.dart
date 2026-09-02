import 'package:flutter/material.dart';

import '../../features/auth/domain/entities/user_role.dart';
import '../../l10n/generated/app_localizations.dart';

/// One navigation branch of the authenticated app — a `StatefulShellBranch`
/// in the router, and (for the ones a given role surfaces) a tab in the
/// bottom navigation.
///
/// Every authenticated route belongs to exactly one branch, and each branch
/// keeps its own [Navigator] and its own scroll position: switching tabs
/// returns you to what you were looking at instead of rebuilding the screen
/// from scratch. That retention is the single change that most makes
/// navigation feel like an app rather than a series of page loads.
///
/// **The declaration order here is the branch order in the router**, and
/// `StatefulNavigationShell.currentIndex` indexes into it — `app_router.dart`
/// builds its branch list by mapping over [AppBranch.values], and asserts the
/// two stay aligned. Don't reorder casually.
enum AppBranch {
  home(
    rootPath: '/dashboard',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  playerProfile(
    rootPath: '/player/preview',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge,
  ),
  playerSkills(
    rootPath: '/player/skills',
    icon: Icons.sports_soccer_outlined,
    selectedIcon: Icons.sports_soccer,
  ),
  playerInvitations(
    rootPath: '/player/invitations',
    icon: Icons.mail_outline,
    selectedIcon: Icons.mail,
  ),
  clubProfile(
    rootPath: '/club/preview',
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield,
  ),
  clubPlayers(
    rootPath: '/club/players',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
  ),
  clubInvitations(
    rootPath: '/club/invitations',
    icon: Icons.mail_outline,
    selectedIcon: Icons.mail,
  ),
  search(
    rootPath: '/search',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
  ),
  savedPlayers(
    rootPath: '/saved-players',
    icon: Icons.bookmark_outline,
    selectedIcon: Icons.bookmark,
  ),
  community(
    rootPath: '/community',
    icon: Icons.groups_2_outlined,
    selectedIcon: Icons.groups_2,
  ),
  // Admin's two screens are separate branches rather than one, so both keep
  // the sidebar row they had before the shell became stateful — they are
  // peers, not a screen and its detail.
  adminUsers(
    rootPath: '/admin/users',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  adminPlayersClubs(
    rootPath: '/admin/players-clubs',
    icon: Icons.manage_accounts_outlined,
    selectedIcon: Icons.manage_accounts,
  ),
  notifications(
    rootPath: '/notifications',
    icon: Icons.notifications_none,
    selectedIcon: Icons.notifications,
  ),
  settings(
    rootPath: '/settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const AppBranch({
    required this.rootPath,
    required this.icon,
    required this.selectedIcon,
  });

  /// Where tapping this branch's tab lands, and where its "up" navigation
  /// bottoms out.
  final String rootPath;

  /// Shown when the tab is not selected. The filled [selectedIcon] takes
  /// over when it is — the weight change is what reads as "you are here"
  /// before the color does.
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (this) {
    home => l10n.marketingNavHome,
    playerProfile => l10n.dashboardMyProfile,
    playerSkills => l10n.skillsSectionTitle,
    playerInvitations => l10n.invitationsTitle,
    clubProfile => l10n.dashboardMyClub,
    clubPlayers => l10n.clubPlayersTitle,
    clubInvitations => l10n.invitationsTitle,
    search => l10n.mobileSearchNavLabel,
    savedPlayers => l10n.dashboardSavedPlayers,
    community => l10n.communityNavLabel,
    adminUsers => l10n.dashboardAdminUsers,
    adminPlayersClubs => l10n.dashboardAdminPlayersClubs,
    notifications => l10n.notificationsTitle,
    settings => l10n.dashboardNavSettings,
  };
}

/// What the app bar shows for one route, and where its back button goes.
class AppRouteMeta {
  const AppRouteMeta({
    required this.title,
    this.parentPath,
    this.ownsChrome = false,
  });

  /// `true` once the screen has moved to `AppScaffoldMobile` and draws its own
  /// collapsing, blurred app bar. The shell then stands down: it renders no
  /// app bar of its own, and lets content scroll under the tab bar.
  ///
  /// Flipping this without migrating the screen leaves it with no app bar at
  /// all; migrating without flipping it leaves two. Both are silent rather
  /// than loud, which is why a test checks the two against each other.
  final bool ownsChrome;

  /// `null` on a branch root that shows the app logo instead of a title —
  /// only Home does, the way a phone app puts its wordmark on the first tab
  /// and a screen name on every other.
  final String Function(AppLocalizations l10n)? title;

  /// Set on a detail screen: the route its back button returns to. Detail
  /// screens navigate with `go` rather than `push` (a branch's routes are
  /// declared flat, so there is no navigator stack to pop), which means back
  /// has to be declared rather than inferred.
  final String? parentPath;
}

/// Static metadata for every authenticated route. Routes carrying a path
/// parameter are matched by [routeMetaFor] rather than by exact key.
final Map<String, AppRouteMeta> _routeMeta = {
  '/dashboard': const AppRouteMeta(title: null, ownsChrome: true),
  '/player/preview': AppRouteMeta(
    title: (l10n) => l10n.dashboardMyProfile,
    ownsChrome: true,
  ),
  '/player/edit': AppRouteMeta(
    title: (l10n) => l10n.dashboardEditProfile,
    parentPath: AppBranch.playerProfile.rootPath,
    ownsChrome: true,
  ),
  '/player/skills': AppRouteMeta(
    title: (l10n) => l10n.skillsSectionTitle,
    ownsChrome: true,
  ),
  '/player/traits': AppRouteMeta(
    title: (l10n) => l10n.traitsTitle,
    parentPath: AppBranch.playerSkills.rootPath,
    ownsChrome: true,
  ),
  '/player/invitations': AppRouteMeta(
    title: (l10n) => l10n.invitationsTitle,
    ownsChrome: true,
  ),
  '/club/preview': AppRouteMeta(
    title: (l10n) => l10n.dashboardMyClub,
    ownsChrome: true,
  ),
  '/club/edit': AppRouteMeta(
    title: (l10n) => l10n.dashboardEditClubProfile,
    parentPath: AppBranch.clubProfile.rootPath,
    ownsChrome: true,
  ),
  '/club/players': AppRouteMeta(
    title: (l10n) => l10n.clubPlayersTitle,
    ownsChrome: true,
  ),
  '/club/players/new': AppRouteMeta(
    title: (l10n) => l10n.clubPlayersAddPlayerLabel,
    parentPath: AppBranch.clubPlayers.rootPath,
    ownsChrome: true,
  ),
  '/club/invitations': AppRouteMeta(
    title: (l10n) => l10n.invitationsTitle,
    ownsChrome: true,
  ),
  '/search': AppRouteMeta(
    title: (l10n) => l10n.dashboardSearchPlayers,
    ownsChrome: true,
  ),
  '/saved-players': AppRouteMeta(
    title: (l10n) => l10n.dashboardSavedPlayers,
    ownsChrome: true,
  ),
  '/community': AppRouteMeta(title: (l10n) => l10n.communityNavLabel),
  '/admin/users': AppRouteMeta(title: (l10n) => l10n.dashboardAdminUsers),
  '/admin/players-clubs': AppRouteMeta(
    title: (l10n) => l10n.dashboardAdminPlayersClubs,
  ),
  '/notifications': AppRouteMeta(
    title: (l10n) => l10n.notificationsTitle,
    ownsChrome: true,
  ),
  '/settings': AppRouteMeta(
    title: (l10n) => l10n.dashboardAccountSettings,
    ownsChrome: true,
  ),
};

/// Metadata for [path], or `null` if it isn't an authenticated app route
/// (the marketing site and the auth pages carry their own chrome).
AppRouteMeta? routeMetaFor(String path) {
  final exact = _routeMeta[path];
  if (exact != null) return exact;

  // The gallery's Settings preview borrows the real screen's metadata, so
  // what it renders is the real bar rather than an approximation of one.
  // Compiled out unless built with --dart-define=SXH_GALLERY=true.
  if (const bool.fromEnvironment('SXH_GALLERY') && path == '/dev/settings') {
    return _routeMeta['/settings'];
  }

  // The one parameterised route in the shell.
  if (path.startsWith('/club/players/') && path.endsWith('/edit')) {
    return AppRouteMeta(
      title: (l10n) => l10n.clubPlayerEditTitle,
      parentPath: AppBranch.clubPlayers.rootPath,
      ownsChrome: true,
    );
  }
  return null;
}

/// The bottom-navigation tabs for [role], in order.
///
/// A Player gets Home, Profile, Skills; a Club gets Home, Club Profile, Club
/// Players, Search; Admin keeps a minimal three. Everything a role can reach
/// but doesn't need a permanent tab for lives in the account sheet behind the
/// last slot — five tabs is the practical ceiling before labels start
/// truncating on a 320px phone.
///
/// Traits is deliberately not a Player tab: it's already shown read-only
/// inside the Profile page (see `TraitsSection`), so a tab for it would be a
/// duplicate.
List<AppBranch> tabBranchesFor(UserRole? role) => switch (role) {
  UserRole.club => const [
    AppBranch.home,
    AppBranch.clubProfile,
    AppBranch.clubPlayers,
    AppBranch.search,
  ],
  UserRole.player => const [
    AppBranch.home,
    AppBranch.playerProfile,
    AppBranch.playerSkills,
    AppBranch.community,
  ],
  _ => const [AppBranch.home, AppBranch.community],
};

/// Branches [role] can reach that aren't tabs — listed in the account sheet.
List<AppBranch> overflowBranchesFor(UserRole? role) {
  final tabs = tabBranchesFor(role);
  final reachable = switch (role) {
    // Invitations is an account-sheet entry rather than a fifth tab: four
    // tabs beside the account slot is the ceiling before labels truncate at
    // 320px, and Club Players is the destination a club opens daily. It
    // still gets a Dashboard quick action, which is where a club that has
    // just added players actually goes looking for it.
    // Notifications is deliberately absent from every list below. It was
    // here while the account sheet was the only route to it; the header
    // bell is now that route, on every screen, and listing it here as well
    // would put the same destination behind two controls one tap apart —
    // with the bell carrying the unread count and the menu row silently
    // not. `/notifications` stays a real route, reached from the bell's
    // panel.
    UserRole.club => const [
      AppBranch.clubInvitations,
      AppBranch.savedPlayers,
      AppBranch.community,
      AppBranch.settings,
    ],
    // Same call as the Club's: Invitations is an account-sheet entry, not a
    // fourth tab displacing Community.
    UserRole.player => const [
      AppBranch.playerInvitations,
      AppBranch.settings,
    ],
    UserRole.admin => const [
      AppBranch.adminUsers,
      AppBranch.adminPlayersClubs,
      AppBranch.settings,
    ],
    _ => const [AppBranch.settings],
  };
  return [
    for (final branch in reachable)
      if (!tabs.contains(branch)) branch,
  ];
}
