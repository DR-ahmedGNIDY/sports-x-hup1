import 'web_push.dart';

/// Non-web. A packaged Android or iOS build would reach the notification
/// tray through FCM/APNs rather than Web Push, and neither is wired up —
/// see the plan's Phase 2 note on why the product ships as web.
PushPermission resolvePushPermission() => PushPermission.unsupported;

Future<String?> runPushSubscribe(String vapidPublicKey) async => null;

Future<String?> readPushSubscription() async => null;

Future<String?> runPushUnsubscribe() async => null;
