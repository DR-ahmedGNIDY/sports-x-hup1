// Phase Mobile M2 — the mobile shell driven through the *real* router, with
// only the session stubbed.
//
// The behaviour this phase is actually buying — a screen's name in the app
// bar, a back button that goes somewhere sensible, a tab bar that shows
// which tab you are on, and tabs that keep their state — all lives in the
// seam between the router's StatefulShellRoute and AppShell. Testing the
// widgets in isolation would test neither the seam nor the branch indices,
// so these mount the router itself.
//
// The pages inside the branches make network calls that fail here; that is
// fine and intentional. They render their error states, the shell renders
// around them, and it's the shell under test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sport_x_hub/core/locale/locale_storage.dart';
import 'package:sport_x_hub/core/locale/locale_storage_provider.dart';
import 'package:sport_x_hub/core/navigation/app_branches.dart';
import 'package:sport_x_hub/core/router/app_router.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/features/auth/application/session_controller.dart';
import 'package:sport_x_hub/features/auth/application/session_state.dart';
import 'package:sport_x_hub/features/auth/domain/entities/app_user.dart';
import 'package:sport_x_hub/features/auth/domain/entities/user_role.dart';
import 'package:sport_x_hub/features/club/application/club_profile_controller.dart';
import 'package:sport_x_hub/features/club/domain/entities/club_profile.dart';
import 'package:sport_x_hub/features/player/application/player_profile_controller.dart';
import 'package:sport_x_hub/features/player/domain/entities/player_profile.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

/// A session that is already authenticated, so the router's redirect lets the
/// shell routes render instead of bouncing to /login.
class _StubSession extends SessionController {
  _StubSession(this.role);

  final UserRole role;

  @override
  SessionState build() => SessionState(
    status: SessionStatus.authenticated,
    user: AppUser(
      id: 'u1',
      email: 'someone@example.test',
      role: role,
      status: 'ACTIVE',
    ),
  );

  @override
  Future<void> restore() async {}
}

class _StubClubProfile extends ClubProfileController {
  @override
  Future<ClubProfile> build() async => const ClubProfile(id: 'c1', name: 'Club');
}

class _StubPlayerProfile extends PlayerProfileController {
  @override
  Future<PlayerProfile> build() async =>
      const PlayerProfile(id: 'p1', firstName: 'Amina', lastName: 'Test');
}

const _phone = Size(390, 844);

Future<GoRouterHarness> _pumpShell(
  WidgetTester tester, {
  UserRole role = UserRole.club,
  String at = '/dashboard',
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sessionControllerProvider.overrideWith(() => _StubSession(role)),
      // The account sheet carries the language toggle, which reads storage.
      localeStorageProvider.overrideWithValue(LocaleStorage(prefs)),
      // The shell's avatar reads the role's profile. Stubbed so these tests
      // exercise navigation rather than the network.
      clubProfileControllerProvider.overrideWith(_StubClubProfile.new),
      playerProfileControllerProvider.overrideWith(_StubPlayerProfile.new),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(appRouterProvider);
  router.go(at);

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
  return GoRouterHarness(router);
}

class GoRouterHarness {
  GoRouterHarness(this.router);

  final dynamic router;

  String get location =>
      router.routerDelegate.currentConfiguration.uri.path as String;
}

AppLocalizations get _en => lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets('the app bar names the screen you are on', (tester) async {
    final harness = await _pumpShell(tester, at: '/club/players');

    expect(harness.location, '/club/players');
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(_en.clubPlayersTitle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Home shows the logo rather than a title', (tester) async {
    await _pumpShell(tester, at: '/dashboard');

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.byType(Image)),
      findsOneWidget,
    );
  });

  testWidgets('a migrated screen gets exactly one app bar', (tester) async {
    // The failure mode `ownsChrome` invites: a screen that draws its own bar
    // while the shell also draws one, or a flag flipped ahead of the
    // migration leaving a screen with none. Both are silent, so every route
    // that claims to own its chrome is checked for exactly one bar.
    for (final path in [
      '/dashboard',
      '/club/players',
      '/club/players/new',
      '/club/preview',
      '/club/edit',
      '/player/preview',
      '/player/skills',
      '/search',
      '/saved-players',
      '/settings',
    ]) {
      expect(routeMetaFor(path)!.ownsChrome, isTrue, reason: path);

      await _pumpShell(tester, at: path);
      // The Player Profile staggers its sections in with delayed timers
      // (FadeSlideIn); leaving them pending at teardown fails the test on a
      // timer rather than on anything it is checking.
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byType(SliverAppBar),
        findsOneWidget,
        reason: '$path should draw its own bar',
      );
      expect(
        find.byType(AppBar),
        findsOneWidget,
        reason: '$path should not also get the shell bar',
      );
    }
  });

  testWidgets('an unmigrated screen still gets the shell bar', (tester) async {
    // Community is the last screen still on the shell's fixed bar.
    await _pumpShell(tester, at: '/community');

    expect(routeMetaFor('/community')!.ownsChrome, isFalse);
    expect(find.byType(SliverAppBar), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('a detail screen offers a back button to its parent', (
    tester,
  ) async {
    final harness = await _pumpShell(tester, at: '/club/players/new');

    final back = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.arrow_back),
    );
    expect(back, findsOneWidget);

    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(harness.location, '/club/players');
  });

  testWidgets('swiping in from the leading edge goes back', (tester) async {
    final harness = await _pumpShell(tester, at: '/club/players/new');

    // Starts inside the 24px edge strip; a drag beginning further in belongs
    // to the page's own content.
    await tester.flingFrom(const Offset(8, 400), const Offset(180, 0), 800);
    await tester.pumpAndSettle();

    expect(harness.location, '/club/players');
  });

  testWidgets('there is no edge-swipe on a screen with nowhere to go', (
    tester,
  ) async {
    final harness = await _pumpShell(tester, at: '/club/players');

    await tester.flingFrom(const Offset(8, 400), const Offset(180, 0), 800);
    await tester.pumpAndSettle();

    expect(harness.location, '/club/players');
  });

  testWidgets('a branch root offers no back button', (tester) async {
    await _pumpShell(tester, at: '/club/preview');

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.arrow_back),
      ),
      findsNothing,
    );
  });

  testWidgets('tapping a tab switches branch and marks it selected', (
    tester,
  ) async {
    final harness = await _pumpShell(tester, at: '/dashboard');

    // The Club's third tab. Tapping the label is enough — the whole slot is
    // one opaque hit target.
    await tester.tap(find.text(_en.clubPlayersTitle));
    await tester.pumpAndSettle();

    expect(harness.location, '/club/players');

    // Selection is shown by the filled icon taking over from the outlined
    // one, which is the part a user actually reads.
    expect(find.byIcon(Icons.groups), findsOneWidget);
    expect(find.byIcon(Icons.groups_outlined), findsNothing);
  });

  testWidgets('a tab keeps its state while you visit another one', (
    tester,
  ) async {
    final harness = await _pumpShell(tester, at: '/club/players/new');
    expect(harness.location, '/club/players/new');

    await tester.tap(find.text(_en.marketingNavHome));
    await tester.pumpAndSettle();
    expect(harness.location, '/dashboard');

    // Back to the Players tab: it returns to the Add screen it was left on
    // rather than resetting to the roster. This is the whole point of the
    // stateful shell.
    await tester.tap(find.text(_en.clubPlayersTitle));
    await tester.pumpAndSettle();
    expect(harness.location, '/club/players/new');
  });

  testWidgets('re-tapping the active tab returns it to its root', (
    tester,
  ) async {
    final harness = await _pumpShell(tester, at: '/club/players/new');

    await tester.tap(find.text(_en.clubPlayersTitle));
    await tester.pumpAndSettle();

    expect(harness.location, '/club/players');
  });

  testWidgets('the account sheet lists what has no tab, and a way out', (
    tester,
  ) async {
    await _pumpShell(tester, at: '/dashboard');

    await tester.tap(find.text(_en.moreNavLabel));
    await tester.pumpAndSettle();

    // A Club's Saved Players / Community / Settings live here rather than
    // crowding a sixth tab.
    expect(find.text(_en.dashboardSavedPlayers), findsOneWidget);
    expect(find.text(_en.communityNavLabel), findsOneWidget);
    expect(find.text(_en.dashboardNavSettings), findsOneWidget);
    expect(find.text(_en.logoutTooltip), findsOneWidget);
  });

  testWidgets('choosing from the account sheet navigates there', (
    tester,
  ) async {
    final harness = await _pumpShell(tester, at: '/dashboard');

    await tester.tap(find.text(_en.moreNavLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.dashboardNavSettings));
    await tester.pumpAndSettle();

    expect(harness.location, '/settings');
  });

  testWidgets('a Player gets Player tabs, not the Club ones', (tester) async {
    // Landed on Settings rather than the Player Profile deliberately: the
    // tabs come from the role, not the route, and mounting the profile page
    // here would make this shell test fail on that page's own internals.
    await _pumpShell(tester, role: UserRole.player, at: '/settings');

    expect(find.text(_en.dashboardMyProfile), findsWidgets);
    expect(find.text(_en.skillsSectionTitle), findsWidgets);
    expect(find.text(_en.clubPlayersTitle), findsNothing);
  });
}
