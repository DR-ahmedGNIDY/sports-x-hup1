// Opening a profile must not cost you the app.
//
// `/players/:id` and `/clubs/:id` live outside the StatefulShellRoute so a
// visitor with no account can open a shared link. A signed-in reader who
// tapped a search result went there too, and lost the tab bar, the header
// and every tab's saved scroll position — on the single most common tap in
// the app. These pin the redirect that keeps them inside.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sport_x_hub/core/locale/locale_storage.dart';
import 'package:sport_x_hub/core/locale/locale_storage_provider.dart';
import 'package:sport_x_hub/core/router/app_router.dart';
import 'package:sport_x_hub/core/storage/session_storage.dart';
import 'package:sport_x_hub/core/storage/session_storage_provider.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/core/widgets/app_shell.dart';
import 'package:sport_x_hub/features/auth/application/session_controller.dart';
import 'package:sport_x_hub/features/auth/application/session_state.dart';
import 'package:sport_x_hub/features/auth/domain/entities/app_user.dart';
import 'package:sport_x_hub/features/auth/domain/entities/user_role.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

/// The shell reads tokens on mount; no platform channel in a test.
class _NoTokens extends SessionStorage {
  _NoTokens() : super(const FlutterSecureStorage());
  @override
  Future<String?> get accessToken async => null;
  @override
  Future<String?> get refreshToken async => null;
}

class _Session extends SessionController {
  _Session({this.signedIn = true, this.role = UserRole.player});

  final bool signedIn;
  final UserRole role;

  @override
  SessionState build() => signedIn
      ? SessionState(
          status: SessionStatus.authenticated,
          user: AppUser(
            id: 'u1',
            email: 'p@example.test',
            role: role,
            status: 'ACTIVE',
          ),
        )
      : const SessionState(status: SessionStatus.unauthenticated);

  @override
  Future<void> restore() async {}
}

Future<_Harness> _pumpAt(
  WidgetTester tester,
  String path, {
  bool signedIn = true,
  UserRole role = UserRole.player,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sessionControllerProvider.overrideWith(
        () => _Session(signedIn: signedIn, role: role),
      ),
      localeStorageProvider.overrideWithValue(LocaleStorage(prefs)),
      sessionStorageProvider.overrideWithValue(_NoTokens()),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(appRouterProvider);
  router.go(path);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.compact(AppTheme.dark),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return _Harness(router);
}

class _Harness {
  _Harness(this.router);
  final dynamic router;
  String get location =>
      router.routerDelegate.currentConfiguration.uri.path as String;
}

void main() {
  testWidgets('a signed-in player keeps the shell on a player profile', (
    tester,
  ) async {
    final harness = await _pumpAt(tester, '/players/abc123');

    expect(harness.location, '/search/players/abc123');
    expect(
      find.byType(AppShell),
      findsOneWidget,
      reason: 'the tab bar vanished on the most common tap in the app',
    );
  });

  testWidgets('a signed-in player keeps the shell on a club profile', (
    tester,
  ) async {
    final harness = await _pumpAt(tester, '/clubs/abc123');

    expect(harness.location, '/search/clubs/abc123');
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('a club keeps it too — both roles have a Search tab', (
    tester,
  ) async {
    await _pumpAt(tester, '/players/abc123', role: UserRole.club);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('a shared link still opens for a visitor with no account', (
    tester,
  ) async {
    final harness = await _pumpAt(
      tester,
      '/players/abc123',
      signedIn: false,
    );

    // The whole reason these routes sit outside the shell.
    expect(harness.location, '/players/abc123');
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('the public listing is not mistaken for a profile', (
    tester,
  ) async {
    final harness = await _pumpAt(tester, '/players');

    // '/players' is the marketing listing, not '/players/:id'.
    expect(harness.location, '/players');
  });

  testWidgets('only one app bar over an in-shell profile', (tester) async {
    await _pumpAt(tester, '/clubs/abc123');

    // The page brings its own; the shell has to stand down or they stack.
    expect(find.byType(AppBar), findsOneWidget);
  });
}
