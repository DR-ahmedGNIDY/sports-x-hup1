// Where the bell is, pinned.
//
// The count has moved once already — from the account avatar to the header
// — and a control that is meant to appear on *every* screen is exactly the
// kind that goes missing on one without anyone noticing. These assert the
// placement rather than the widget's own behaviour, which
// `notifications_test.dart` covers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_x_hub/core/navigation/app_branches.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/core/widgets/mobile/app_scaffold_mobile.dart';
import 'package:sport_x_hub/features/auth/application/session_controller.dart';
import 'package:sport_x_hub/features/auth/application/session_state.dart';
import 'package:sport_x_hub/features/auth/domain/entities/app_user.dart';
import 'package:sport_x_hub/features/auth/domain/entities/user_role.dart';
import 'package:sport_x_hub/features/notifications/presentation/shared/notification_bell.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

class _Session extends SessionController {
  _Session({this.authenticated = true});

  final bool authenticated;

  @override
  SessionState build() => authenticated
      ? const SessionState(
          status: SessionStatus.authenticated,
          user: AppUser(
            id: 'u1',
            role: UserRole.player,
            email: 'p@example.test',
            status: 'ACTIVE',
          ),
        )
      : const SessionState(status: SessionStatus.unauthenticated);
}

Future<void> _pumpMobileScreen(
  WidgetTester tester, {
  String location = '/player/preview',
  List<Widget>? screenActions,
  bool authenticated = true,
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: location,
        builder: (_, _) =>
            AppScaffoldMobile(slivers: const [], actions: screenActions),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(
          () => _Session(authenticated: authenticated),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.compact(AppTheme.dark),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('the bell in the mobile header', () {
    testWidgets('is there on a branch root', (tester) async {
      await _pumpMobileScreen(tester);
      expect(find.byType(NotificationBell), findsOneWidget);
    });

    testWidgets('is there on a detail screen too', (tester) async {
      // A detail screen renders a back button and a small title instead of
      // the collapsing large one — a different branch of the same bar.
      await _pumpMobileScreen(tester, location: '/player/edit');
      expect(find.byType(NotificationBell), findsOneWidget);
    });

    testWidgets('does not displace a screen own actions', (tester) async {
      await _pumpMobileScreen(
        tester,
        screenActions: const [Icon(Icons.edit_outlined, key: Key('screen'))],
      );

      expect(find.byKey(const Key('screen')), findsOneWidget);
      expect(find.byType(NotificationBell), findsOneWidget);
    });

    testWidgets('is absent when signed out', (tester) async {
      await _pumpMobileScreen(tester, authenticated: false);
      // A bell that always says zero is chrome, not information.
      expect(find.byType(NotificationBell), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsNothing);
    });
  });

  group('the account sheet', () {
    test('no longer lists Notifications for any role', () {
      // The header bell is the route now. Listing it here as well would put
      // one destination behind two controls a tap apart, with only one of
      // them carrying the unread count.
      for (final role in [...UserRole.values, null]) {
        expect(
          overflowBranchesFor(role),
          isNot(contains(AppBranch.notifications)),
          reason: '$role',
        );
        expect(
          tabBranchesFor(role),
          isNot(contains(AppBranch.notifications)),
          reason: '$role',
        );
      }
    });
  });
}
