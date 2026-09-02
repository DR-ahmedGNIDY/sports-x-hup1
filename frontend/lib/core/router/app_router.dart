import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_players_clubs_page.dart';
import '../../features/admin/presentation/admin_users_page.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/application/session_state.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/club/presentation/edit_club_profile_page.dart';
import '../../features/club/presentation/my_club_profile_page.dart';
import '../../features/club/presentation/public_club_profile_page.dart';
import '../../features/club/presentation/public_clubs_listing_page.dart';
import '../../features/club_players/presentation/add_club_player_page.dart';
import '../../features/club_players/presentation/club_players_page.dart';
import '../../features/club_players/presentation/edit_club_player_page.dart';
import '../../features/community/presentation/community_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/invitations/presentation/club_invitations_page.dart';
import '../../features/invitations/presentation/player_invitations_page.dart';
import '../../features/marketing/presentation/about_page.dart';
import '../../features/marketing/presentation/contact_page.dart';
import '../../features/marketing/presentation/home_page.dart';
import '../../features/marketing/presentation/pricing_page.dart';
import '../../features/player/presentation/edit_profile_page.dart';
import '../../features/player/presentation/my_profile_preview_page.dart';
import '../../features/player/presentation/my_skills_page.dart';
import '../../features/player/presentation/my_traits_page.dart';
import '../../features/player/presentation/public_player_profile_page.dart';
import '../../features/saved_players/presentation/saved_players_page.dart';
import '../../features/search/presentation/public_players_listing_page.dart';
import '../../features/search/presentation/search_players_page.dart';
import '../../features/settings/presentation/mobile/settings_page_mobile.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../navigation/app_branches.dart';
import '../widgets/app_shell.dart';
import '../widgets/mobile/component_gallery_page.dart';
import 'app_page_transitions.dart';
import 'go_router_refresh_notifier.dart';

// Guest-only auth pages — an authenticated user is bounced away from these.
const _publicRoutes = {'/login', '/register', '/forgot-password', '/reset-password'};

// The public marketing site (Phase 5) — reachable with or without a
// session, and never bounces an authenticated user away either: a logged-in
// Club can still browse About/Pricing, same as anyone else.
const _marketingRoutes = {'/home', '/about', '/pricing', '/contact', '/players', '/clubs'};

/// Public player profiles and public club profiles are shareable URLs:
/// reachable with or without a session, so unlike [_publicRoutes] they
/// never trigger the "authenticated users get bounced to /dashboard"
/// redirect.
bool _isPublicPlayerProfile(String path) => path.startsWith('/players/');
bool _isPublicClubProfile(String path) => path.startsWith('/clubs/');

bool _isMarketingRoute(String path) =>
    _marketingRoutes.contains(path) ||
    _isPublicPlayerProfile(path) ||
    _isPublicClubProfile(path);

/// Compiled in only when built with `--dart-define=SXH_GALLERY=true`. Guards
/// the component gallery (see [ComponentGalleryPage]) — a preview surface for
/// components that otherwise only exist behind a login, and one that has no
/// business in a production bundle.
const _galleryEnabled = bool.fromEnvironment('SXH_GALLERY');
const _galleryRoute = '/dev/gallery';

bool _isAdminRoute(String path) => path.startsWith('/admin/');

bool _isClubRoute(String path) =>
    path.startsWith('/club/players') || path.startsWith('/club/invitations');

// Narrower than it looks: the Player profile and skills screens are not
// listed, because they have always been reachable by any role (they render
// the caller's own profile, and a Club simply has none). Invitations is
// different — its send action is PLAYER-only on the server, so a Club that
// wandered in would meet a 403 instead of a screen.
bool _isPlayerRoute(String path) => path.startsWith('/player/invitations');

// Where an authenticated session lands after splash/login, or gets bounced
// back to when it hits a route it doesn't own — a Player's home is their
// own profile, everyone else's is the dashboard.
String _landingRoute(SessionState session) =>
    session.user?.role == UserRole.player ? '/player/preview' : '/dashboard';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshNotifier(ref, sessionControllerProvider),
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final path = state.matchedLocation;

      // The public marketing site and public profile/listing deep links are
      // session-independent — checked before the splash gate below, so a
      // cold load renders the page directly instead of being forced through
      // '/' and losing the requested path once restore() resolves.
      if (_isMarketingRoute(path)) return null;

      // Session-independent for the same reason: it renders components, not
      // anyone's data.
      if (_galleryEnabled && path.startsWith('/dev/')) return null;

      // Force every cold load through splash first, so it can call
      // SessionController.restore() before any protected/public route
      // renders — a direct deep link during this window would otherwise
      // render with an unverified session.
      if (session.status == SessionStatus.unknown) {
        return path == '/' ? null : '/';
      }

      final isAuthenticated = session.status == SessionStatus.authenticated;

      // Root '/' is the technical splash/session-restore route, not a page
      // in its own right — once restore() resolves, send the visitor
      // straight to their dashboard or to the marketing home page.
      if (path == '/') {
        return isAuthenticated ? _landingRoute(session) : '/home';
      }

      final isPublicRoute = _publicRoutes.contains(path);
      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated && isPublicRoute) return _landingRoute(session);

      // Admin tooling is only for ADMIN accounts — everyone else gets
      // bounced back to their own landing route, same as a Player hitting a
      // Club-only route would be if one existed.
      if (_isAdminRoute(path) && session.user?.role != UserRole.admin) {
        return _landingRoute(session);
      }

      // Adding/managing players directly is a Club-only tool, same
      // enforcement shape as the admin check above.
      if (_isClubRoute(path) && session.user?.role != UserRole.club) {
        return _landingRoute(session);
      }
      if (_isPlayerRoute(path) && session.user?.role != UserRole.player) {
        return _landingRoute(session);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      if (_galleryEnabled) ...[
        GoRoute(
          path: _galleryRoute,
          builder: (context, state) => const ComponentGalleryPage(),
        ),
        // The real Settings screen, previewed without the shell around it —
        // enough to see AppScaffoldMobile's collapsing blurred bar and the
        // grouped rows. The session is whatever the browser has, so the
        // account email is blank here rather than stubbed.
        GoRoute(
          path: '/dev/settings',
          builder: (context, state) => const SettingsPageMobile(),
        ),
      ],
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
      GoRoute(path: '/pricing', builder: (context, state) => const PricingPage()),
      GoRoute(path: '/contact', builder: (context, state) => const ContactPage()),
      GoRoute(
        path: '/players',
        builder: (context, state) => const PublicPlayersListingPage(),
      ),
      GoRoute(
        path: '/clubs',
        builder: (context, state) => const PublicClubsListingPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordPage(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/players/:id',
        builder: (context, state) =>
            PublicPlayerProfilePage(playerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clubs/:id',
        builder: (context, state) =>
            PublicClubProfilePage(clubId: state.pathParameters['id']!),
      ),
      // The authenticated app shares one persistent shell (sidebar/topbar on
      // desktop, bottom-nav/topbar on mobile) so navigating between screens
      // never loses the app chrome.
      //
      // It's a *stateful* shell: each branch below owns a Navigator and keeps
      // its own state and scroll position, so switching tabs returns you to
      // what you were looking at instead of rebuilding the screen. That's the
      // difference between "the app remembered where I was" and "the page
      // reloaded", and it is why the branch list is derived from
      // [AppBranch.values] — the shell reads `currentIndex` back out of it.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [for (final branch in AppBranch.values) _branchFor(branch)],
      ),
    ],
  );
});

/// The routes belonging to [branch]. Every authenticated route lives in
/// exactly one branch; a screen reached *from* another screen (an edit form,
/// an add form) belongs to the same branch as the screen that owns it, so
/// opening it keeps the tab you were on selected.
///
/// The routes within a branch are declared flat rather than nested, which
/// keeps every URL exactly as it was — `/player/edit` did not become
/// `/player/preview/edit`. The trade is that there is no navigator stack to
/// pop, so a detail screen declares where its back button goes via
/// [AppRouteMeta.parentPath] instead.
StatefulShellBranch _branchFor(AppBranch branch) {
  return StatefulShellBranch(
    routes: switch (branch) {
      AppBranch.home => [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const DashboardPage()),
        ),
      ],
      AppBranch.playerProfile => [
        GoRoute(
          path: '/player/preview',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const MyProfilePreviewPage()),
        ),
        GoRoute(
          path: '/player/edit',
          pageBuilder: (context, state) =>
              slidePage(state: state, child: const EditProfilePage()),
        ),
      ],
      AppBranch.playerSkills => [
        GoRoute(
          path: '/player/skills',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const MySkillsPage()),
        ),
        GoRoute(
          path: '/player/traits',
          pageBuilder: (context, state) =>
              slidePage(state: state, child: const MyTraitsPage()),
        ),
      ],
      AppBranch.playerInvitations => [
        GoRoute(
          path: '/player/invitations',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const PlayerInvitationsPage()),
        ),
      ],
      AppBranch.clubProfile => [
        GoRoute(
          path: '/club/preview',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const MyClubProfilePage()),
        ),
        GoRoute(
          path: '/club/edit',
          pageBuilder: (context, state) =>
              slidePage(state: state, child: const EditClubProfilePage()),
        ),
      ],
      AppBranch.clubPlayers => [
        GoRoute(
          path: '/club/players',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const ClubPlayersPage()),
        ),
        GoRoute(
          path: '/club/players/new',
          pageBuilder: (context, state) =>
              slidePage(state: state, child: const AddClubPlayerPage()),
        ),
        GoRoute(
          path: '/club/players/:userId/edit',
          pageBuilder: (context, state) => slidePage(
            state: state,
            child: EditClubPlayerPage(userId: state.pathParameters['userId']!),
          ),
        ),
      ],
      AppBranch.clubInvitations => [
        GoRoute(
          path: '/club/invitations',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const ClubInvitationsPage()),
        ),
      ],
      AppBranch.search => [
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const SearchPlayersPage()),
        ),
      ],
      AppBranch.savedPlayers => [
        GoRoute(
          path: '/saved-players',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const SavedPlayersPage()),
        ),
      ],
      AppBranch.community => [
        GoRoute(
          path: '/community',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const CommunityPage()),
        ),
      ],
      AppBranch.adminUsers => [
        GoRoute(
          path: '/admin/users',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const AdminUsersPage()),
        ),
      ],
      AppBranch.adminPlayersClubs => [
        GoRoute(
          path: '/admin/players-clubs',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const AdminPlayersClubsPage()),
        ),
      ],
      AppBranch.settings => [
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              fadePage(state: state, child: const SettingsPage()),
        ),
      ],
    },
  );
}
