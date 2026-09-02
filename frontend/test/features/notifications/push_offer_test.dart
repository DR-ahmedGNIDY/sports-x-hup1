// What the app decides to offer on a given device.
//
// This is the piece worth pinning: a browser grants one permission prompt,
// effectively forever, so offering at the wrong moment or in the wrong
// state spends something that cannot be got back.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/errors/app_exception.dart';
import 'package:sport_x_hub/features/notifications/application/push_controller.dart';
import 'package:sport_x_hub/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:sport_x_hub/features/notifications/domain/entities/notifications_page.dart';
import 'package:sport_x_hub/features/notifications/domain/repositories/notifications_repository.dart';

class _Repository implements NotificationsRepository {
  _Repository({this.publicKey, this.throwsOnKey = false});

  final String? publicKey;
  final bool throwsOnKey;
  final List<Map<String, dynamic>> subscribed = [];

  @override
  Future<String?> pushPublicKey() async {
    if (throwsOnKey) throw const AppException('server unreachable');
    return publicKey;
  }

  @override
  Future<void> subscribePush(Map<String, dynamic> subscription) async =>
      subscribed.add(subscription);

  @override
  Future<void> unsubscribePush(String endpoint) async {}

  @override
  Future<NotificationsPage> list({int page = 1, bool unreadOnly = false}) async =>
      NotificationsPage.empty;

  @override
  Future<int> unreadCount() async => 0;

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<int> markAllRead() async => 0;
}

ProviderContainer _containerWith(_Repository repository) {
  final container = ProviderContainer(
    overrides: [
      notificationsRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('PushController.offer', () {
    // These run on the Dart VM, where `WebPush` is the non-web stub and
    // reports `unsupported`. That is exactly the state to pin here: the app
    // must stay quiet on a platform that cannot do Web Push at all, rather
    // than showing an affordance that would do nothing.
    test('offers nothing on a platform without Web Push', () async {
      final container = _containerWith(_Repository(publicKey: 'vapid-key'));

      final offer = await container.read(pushControllerProvider).offer();

      expect(offer, PushOffer.unavailable);
    });

    test('enable() gives up rather than prompting when there is no key', () async {
      final repository = _Repository(publicKey: null);
      final container = _containerWith(repository);

      // A browser gives you one prompt. Spending it on a backend with no
      // VAPID keys would burn it permanently for nothing.
      expect(
        container.read(pushControllerProvider).enable(),
        completion(isFalse),
      );
      expect(repository.subscribed, isEmpty);
    });

    test('a failed key lookup is not an error the user sees', () async {
      final container = _containerWith(_Repository(throwsOnKey: true));

      // Push is an addition on top of the durable in-app notification;
      // a backend hiccup here must degrade to "no banner", not to a crash.
      expect(
        container.read(pushControllerProvider).offer(),
        completion(PushOffer.unavailable),
      );
      expect(
        container.read(pushControllerProvider).enable(),
        completion(isFalse),
      );
    });
  });
}
