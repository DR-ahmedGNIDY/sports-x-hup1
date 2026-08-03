import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/application/session_state.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/player/presentation/edit_profile_page.dart';
import '../../features/player/presentation/my_profile_preview_page.dart';
import '../../features/player/presentation/public_player_profile_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import 'go_router_refresh_notifier.dart';

// Guest-only auth pages — an authenticated user is bounced away from these.
const _publicRoutes = {'/login', '/register', '/forgot-password', '/reset-password'};

/// Public player profiles are shareable URLs: reachable with or without a
/// session, so unlike [_publicRoutes] they never trigger the "authenticated
/// users get bounced to /dashboard" redirect.
bool _isPublicPlayerProfile(String path) => path.startsWith('/players/');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshNotifier(ref, sessionControllerProvider),
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final path = state.matchedLocation;

      // Public player profiles are shareable, session-independent deep
      // links — checked before the splash gate below, so a cold load
      // renders the profile directly instead of being forced through '/'
      // and losing the requested path once restore() resolves.
      if (_isPublicPlayerProfile(path)) return null;

      // Force every cold load through splash first, so it can call
      // SessionController.restore() before any protected/public route
      // renders — a direct deep link during this window would otherwise
      // render with an unverified session.
      if (session.status == SessionStatus.unknown) {
        return path == '/' ? null : '/';
      }

      final isAuthenticated = session.status == SessionStatus.authenticated;
      final isPublicRoute = _publicRoutes.contains(path);

      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated && (path == '/' || isPublicRoute)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
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
    ],
  );
});
