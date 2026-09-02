// The Player's Search tab, driven through the real router.
//
// This screen is two tabs wrapping a page that was written to own a whole
// route, so the thing worth testing is that it still lays out when it no
// longer does.

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
import 'package:sport_x_hub/features/auth/application/session_controller.dart';
import 'package:sport_x_hub/features/auth/application/session_state.dart';
import 'package:sport_x_hub/features/auth/domain/entities/app_user.dart';
import 'package:sport_x_hub/features/auth/domain/entities/user_role.dart';
import 'package:sport_x_hub/features/club/application/club_profile_controller.dart';
import 'package:sport_x_hub/features/club/application/club_search_controller.dart';
import 'package:sport_x_hub/features/club/domain/entities/club_list_page.dart';
import 'package:sport_x_hub/features/club/domain/entities/club_profile.dart';
import 'package:sport_x_hub/features/player/application/player_profile_controller.dart';
import 'package:sport_x_hub/features/player/domain/entities/player_profile.dart';
import 'package:sport_x_hub/features/player/domain/entities/player_search_result.dart';
import 'package:sport_x_hub/features/saved_players/application/saved_players_controller.dart';
import 'package:sport_x_hub/features/search/application/search_controller.dart';
import 'package:sport_x_hub/features/search/domain/entities/player_search_page.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

class _StubSession extends SessionController {
  _StubSession(this.role);
  final UserRole role;
  @override
  SessionState build() => SessionState(
    status: SessionStatus.authenticated,
    user: AppUser(id: 'u1', email: 'p@example.test', role: role, status: 'ACTIVE'),
  );
  @override
  Future<void> restore() async {}
}

/// No tokens, no platform channel — the bell asks for one on mount.
class _NoTokens extends SessionStorage {
  _NoTokens() : super(const FlutterSecureStorage());
  @override
  Future<String?> get accessToken async => null;
  @override
  Future<String?> get refreshToken async => null;
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

/// Two results, the way production actually answers.
class _StubSearch extends PlayerSearchController {
  @override
  Future<PlayerSearchPage> build() async => const PlayerSearchPage(
    items: [
      PlayerSearchResult(id: 'p1', firstName: 'Ahmed', lastName: 'Ali'),
      PlayerSearchResult(id: 'p2', firstName: 'Test', lastName: 'Player'),
    ],
    page: 1,
    pageSize: 20,
    total: 2,
  );
}

class _StubClubSearch extends ClubSearchController {
  @override
  Future<ClubListPage> build() async => const ClubListPage(
    items: [ClubProfile(id: 'c1', name: 'Zamalek Academy')],
    page: 1,
    pageSize: 20,
    total: 1,
  );
}


/// saved-players answers a Player with 403. This reproduces that directly
/// rather than leaning on the harness happening to be unauthenticated.
class _FailingSavedPlayers extends SavedPlayersController {
  @override
  Future<List<PlayerSearchResult>> build() async =>
      throw Exception("403 Forbidden");
}

const _phone = Size(390, 844);

Future<void> _pumpAt(
  WidgetTester tester,
  String at, {
  UserRole role = UserRole.player,
  List<Override> extraOverrides = const [],
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sessionControllerProvider.overrideWith(() => _StubSession(role)),
      localeStorageProvider.overrideWithValue(LocaleStorage(prefs)),
      sessionStorageProvider.overrideWithValue(
        _NoTokens(),
      ),
      clubProfileControllerProvider.overrideWith(_StubClubProfile.new),
      playerProfileControllerProvider.overrideWith(_StubPlayerProfile.new),
      searchControllerProvider.overrideWith(_StubSearch.new),
      clubSearchControllerProvider.overrideWith(_StubClubSearch.new),
      ...extraOverrides,
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
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a Player opens Search and both results render', (tester) async {
    await _pumpAt(tester, '/search');

    expect(tester.takeException(), isNull, reason: 'Search threw on open');
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Test Player'), findsOneWidget);
  });

  testWidgets('switching to Clubs keeps the screen laid out', (tester) async {
    await _pumpAt(tester, '/search');

    await tester.tap(find.text('Clubs'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'Clubs tab threw');
    expect(find.text('Zamalek Academy'), findsOneWidget);
  });
// The bug this screen shipped with. saved-players is Club-only, so every
  // result card on a Player search rebuilt from an AsyncError — and
  // AsyncValue.value rethrows one, which took out the whole list and left
  // blank space under the search box. The card must not consult a provider
  // that is not its viewer to consult.
  testWidgets("a Player still sees results when saved-players is forbidden", (
    tester,
  ) async {
    await _pumpAt(
      tester,
      "/search",
      extraOverrides: [
        savedPlayersControllerProvider.overrideWith(_FailingSavedPlayers.new),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text("Ahmed Ali"), findsOneWidget);
    expect(find.text("Test Player"), findsOneWidget);
  });
}
