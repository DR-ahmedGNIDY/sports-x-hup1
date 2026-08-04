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
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/marketing/presentation/about_page.dart';
import '../../features/marketing/presentation/contact_page.dart';
import '../../features/marketing/presentation/home_page.dart';
import '../../features/marketing/presentation/pricing_page.dart';
import '../../features/player/presentation/edit_profile_page.dart';
import '../../features/player/presentation/my_profile_preview_page.dart';
import '../../features/player/presentation/public_player_profile_page.dart';
import '../../features/saved_players/presentation/saved_players_page.dart';
import '../../features/search/presentation/public_players_listing_page.dart';
import '../../features/search/presentation/search_players_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/splash/presentation/splash_page.dart';
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

bool _isAdminRoute(String path) => path.startsWith('/admin/');

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
        return isAuthenticated ? '/dashboard' : '/home';
      }

      final isPublicRoute = _publicRoutes.contains(path);
      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated && isPublicRoute) return '/dashboard';

      // Admin tooling is only for ADMIN accounts — everyone else gets
      // bounced back to their own dashboard, same as a Player hitting a
      // Club-only route would be if one existed.
      if (_isAdminRoute(path) && session.user?.role != UserRole.admin) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
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
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
      GoRoute(
        path: '/player/edit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/player/preview',
        builder: (context, state) => const MyProfilePreviewPage(),
      ),
      GoRoute(
        path: '/players/:id',
        builder: (context, state) =>
            PublicPlayerProfilePage(playerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/club/edit',
        builder: (context, state) => const EditClubProfilePage(),
      ),
      GoRoute(
        path: '/club/preview',
        builder: (context, state) => const MyClubProfilePage(),
      ),
      GoRoute(
        path: '/clubs/:id',
        builder: (context, state) =>
            PublicClubProfilePage(clubId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/search', builder: (context, state) => const SearchPlayersPage()),
      GoRoute(
        path: '/saved-players',
        builder: (context, state) => const SavedPlayersPage(),
      ),
      GoRoute(path: '/admin/users', builder: (context, state) => const AdminUsersPage()),
      GoRoute(
        path: '/admin/players-clubs',
        builder: (context, state) => const AdminPlayersClubsPage(),
      ),
    ],
  );
});
