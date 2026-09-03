// The navigation bar has to outlive a failed side request.
//
// The account slot in the bottom bar shows the signed-in user's avatar,
// which it reads from the profile controller. That read used `.value`,
// which *rethrows* an AsyncError rather than answering null — so a profile
// request that failed threw while building the bar and took the Column
// holding every tab down with it. From the outside it looked like the
// navigation buttons vanishing at random.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:sport_x_hub/features/club/domain/entities/club_profile.dart';
import 'package:sport_x_hub/features/player/application/player_profile_controller.dart';
import 'package:sport_x_hub/features/player/domain/entities/player_profile.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

class _NoTokens extends SessionStorage {
  _NoTokens() : super(const FlutterSecureStorage());
  @override
  Future<String?> get accessToken async => null;
  @override
  Future<String?> get refreshToken async => null;
}

class _Session extends SessionController {
  _Session(this.role);
  final UserRole role;
  @override
  SessionState build() => SessionState(
    status: SessionStatus.authenticated,
    user: AppUser(id: 'u1', email: 'someone@example.test', role: role, status: 'ACTIVE'),
  );
  @override
  Future<void> restore() async {}
}

/// The profile request failing, which is the whole point of these tests.
class _FailingPlayerProfile extends PlayerProfileController {
  @override
  Future<PlayerProfile> build() async => throw Exception('offline');
}

class _FailingClubProfile extends ClubProfileController {
  @override
  Future<ClubProfile> build() async => throw Exception('offline');
}

Future<void> _pump(WidgetTester tester, UserRole role) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sessionControllerProvider.overrideWith(() => _Session(role)),
      localeStorageProvider.overrideWithValue(LocaleStorage(prefs)),
      sessionStorageProvider.overrideWithValue(_NoTokens()),
      playerProfileControllerProvider.overrideWith(_FailingPlayerProfile.new),
      clubProfileControllerProvider.overrideWith(_FailingClubProfile.new),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(appRouterProvider);
  router.go('/dashboard');

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
}

void main() {
  testWidgets('a Player keeps every tab when the profile request fails', (
    tester,
  ) async {
    await _pump(tester, UserRole.player);

    expect(
      tester.takeException(),
      isNull,
      reason: 'the bottom bar threw and took the tabs with it',
    );

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.marketingNavHome), findsOneWidget);
    expect(find.text(l10n.mobileSearchNavLabel), findsOneWidget);
    expect(find.text(l10n.communityNavLabel), findsOneWidget);
  });

  testWidgets('a Club keeps every tab when the profile request fails', (
    tester,
  ) async {
    await _pump(tester, UserRole.club);

    expect(tester.takeException(), isNull);

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.clubPlayersTitle), findsOneWidget);
    expect(find.text(l10n.mobileSearchNavLabel), findsOneWidget);
  });
}
