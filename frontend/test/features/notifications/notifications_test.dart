// The notification layer's two jobs: decode without breaking on a row it
// does not understand, and never render text the server wrote.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/features/auth/application/session_controller.dart';
import 'package:sport_x_hub/features/auth/application/session_state.dart';
import 'package:sport_x_hub/features/auth/domain/entities/app_user.dart';
import 'package:sport_x_hub/features/auth/domain/entities/user_role.dart';
import 'package:sport_x_hub/features/notifications/application/notifications_controller.dart';
import 'package:sport_x_hub/features/notifications/data/models/notification_model.dart';
import 'package:sport_x_hub/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:sport_x_hub/features/notifications/domain/entities/app_notification.dart';
import 'package:sport_x_hub/features/notifications/domain/entities/notifications_page.dart';
import 'package:sport_x_hub/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:sport_x_hub/features/notifications/presentation/shared/notification_badge.dart';
import 'package:sport_x_hub/features/notifications/presentation/shared/notification_labels.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

import '../../support/app_fonts.dart';

Map<String, dynamic> _row({
  String type = 'INVITATION_RECEIVED',
  String actorRole = 'CLUB',
  String? actorName = 'Al Ahly',
  bool read = false,
}) => {
  'id': 'n1',
  'type': type,
  'params': <String, dynamic>{
    'actorRole': actorRole,
    'actorName': actorName,
    'actorProfileId': 'club-profile-1',
    'actorPublicCode': 'CLB-000001',
  },
  'entityType': 'INVITATION',
  'entityId': 'invitation-1',
  'read': read,
  'createdAt': '2026-02-01T10:00:00.000Z',
};

class _FakeRepository implements NotificationsRepository {
  _FakeRepository({this.page = NotificationsPage.empty, this.unread = 0});

  NotificationsPage page;
  int unread;
  final List<String> markedRead = [];
  int markAllCalls = 0;

  @override
  Future<NotificationsPage> list({int page = 1, bool unreadOnly = false}) async =>
      this.page;

  @override
  Future<int> unreadCount() async => unread;

  @override
  Future<void> markRead(String id) async => markedRead.add(id);

  @override
  Future<int> markAllRead() async {
    markAllCalls += 1;
    return unread;
  }
}

class _StubSession extends SessionController {
  _StubSession({this.authenticated = true});

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

AppNotification _decode(Map<String, dynamic> json) =>
    AppNotificationModel.fromJson(json)!;

void main() {
  setUpAll(loadAppFonts);

  group('AppNotificationModel', () {
    test('decodes a notification and its actor', () {
      final n = _decode(_row());

      expect(n.id, 'n1');
      expect(n.type, NotificationType.invitationReceived);
      expect(n.actor.role, NotificationActorRole.club);
      expect(n.actor.name, 'Al Ahly');
      expect(n.actor.publicCode, 'CLB-000001');
      expect(n.entityId, 'invitation-1');
      expect(n.read, isFalse);
    });

    test('an unknown type decodes to null instead of throwing', () {
      // A backend that learns a new notification type must not crash a
      // client that predates it.
      expect(AppNotificationModel.fromJson(_row(type: 'SOMETHING_NEW')), isNull);
    });

    test('a page drops rows it cannot render but keeps the server’s total', () {
      final page = NotificationsPageModel.fromJson({
        'items': [_row(), _row(type: 'SOMETHING_NEW')],
        'page': 1,
        'pageSize': 20,
        'total': 2,
      });

      expect(page.items, hasLength(1));
      // Reporting 1 here would break pagination — the server counted both.
      expect(page.total, 2);
    });
  });

  group('notificationText', () {
    late AppLocalizations l10n;

    setUp(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('a club inviting and a player asking read as different sentences', () {
      final fromClub = _decode(_row(actorRole: 'CLUB', actorName: 'Al Ahly'));
      final fromPlayer = _decode(_row(actorRole: 'PLAYER', actorName: 'Omar'));

      expect(notificationText(l10n, fromClub), contains('Al Ahly'));
      expect(notificationText(l10n, fromPlayer), contains('Omar'));
      expect(
        notificationText(l10n, fromClub),
        isNot(notificationText(l10n, fromPlayer)),
      );
    });

    test('a nameless actor falls back rather than rendering a blank', () {
      final club = _decode(_row(actorName: null));
      final player = _decode(_row(actorRole: 'PLAYER', actorName: ''));

      expect(notificationText(l10n, club), contains(l10n.unnamedClub));
      expect(notificationText(l10n, player), contains(l10n.unnamedPlayer));
    });

    test('the same notification renders in the reader’s current language', () async {
      final ar = await AppLocalizations.delegate.load(const Locale('ar'));
      final n = _decode(_row());

      // The point of storing params rather than a sentence: history follows
      // the reader, it is not frozen in whatever language wrote it.
      expect(notificationText(ar, n), isNot(notificationText(l10n, n)));
      expect(notificationText(ar, n), contains('Al Ahly'));
    });
  });

  group('NotificationsListController', () {
    ProviderContainer containerWith(_FakeRepository repository) {
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          sessionControllerProvider.overrideWith(_StubSession.new),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('marking one read flips the row in place', () async {
      final repository = _FakeRepository(
        page: NotificationsPage(
          items: [_decode(_row())],
          page: 1,
          pageSize: 20,
          total: 1,
        ),
      );
      final container = containerWith(repository);

      await container.read(notificationsListProvider.future);
      await container.read(notificationsListProvider.notifier).markRead('n1');

      final items = container.read(notificationsListProvider).value!.items;
      // Patched, not refetched — the row must not jump or vanish under the
      // finger that tapped it.
      expect(items.single.read, isTrue);
      expect(repository.markedRead, ['n1']);
    });

    test('marking an already-read row writes nothing', () async {
      final repository = _FakeRepository(
        page: NotificationsPage(
          items: [_decode(_row(read: true))],
          page: 1,
          pageSize: 20,
          total: 1,
        ),
      );
      final container = containerWith(repository);

      await container.read(notificationsListProvider.future);
      await container.read(notificationsListProvider.notifier).markRead('n1');

      expect(repository.markedRead, isEmpty);
    });

    test('the unread filter resets to page one', () async {
      final repository = _FakeRepository();
      final container = containerWith(repository);

      await container.read(notificationsListProvider.future);
      final controller = container.read(notificationsListProvider.notifier);
      await controller.loadPage(3);
      await controller.applyUnreadOnly(true);

      expect(controller.unreadOnly, isTrue);
      expect(container.read(notificationsListProvider).value!.page, 1);
    });
  });

  group('unreadNotificationsProvider', () {
    test('answers zero without a request when signed out', () async {
      final repository = _FakeRepository(unread: 5);
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          sessionControllerProvider.overrideWith(
            () => _StubSession(authenticated: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      // A badge must not survive a logout, and a logged-out visitor must not
      // fire an authenticated request on every app start.
      expect(
        container.read(unreadNotificationsProvider.future),
        completion(0),
      );
    });

    test('reads the count when signed in', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(
            _FakeRepository(unread: 3),
          ),
          sessionControllerProvider.overrideWith(_StubSession.new),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(unreadNotificationsProvider.future),
        completion(3),
      );
    });
  });

  group('NotificationBadge', () {
    Future<void> pump(WidgetTester tester, int unread) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(
              _FakeRepository(unread: unread),
            ),
            sessionControllerProvider.overrideWith(_StubSession.new),
          ],
          child: MaterialApp(
            theme: AppTheme.compact(AppTheme.dark),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: Center(
                child: NotificationBadge(child: Icon(Icons.person)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows nothing at zero', (tester) async {
      await pump(tester, 0);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows the count', (tester) async {
      await pump(tester, 3);
      // A number, not a dot: "3" tells you whether to open it now.
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('caps at 9+ rather than growing without limit', (tester) async {
      await pump(tester, 42);
      expect(find.text('9+'), findsOneWidget);
    });
  });
}
