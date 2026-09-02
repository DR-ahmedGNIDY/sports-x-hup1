import 'web_push_stub.dart'
    if (dart.library.js_interop) 'web_push_web.dart';

/// What the browser currently allows.
enum PushPermission {
  /// The browser has push, and nobody has answered the prompt yet.
  prompt,

  granted,

  /// Refused. Browsers make re-asking deliberately hard, so this is close
  /// to permanent — which is why the prompt's timing matters more than any
  /// other decision in this feature.
  denied,

  /// No PushManager at all: Safari before 16.4, any iOS browser outside an
  /// installed PWA, some privacy-hardened builds — and every non-web build,
  /// where this whole file is a no-op.
  unsupported,
}

/// Web Push, behind the same conditional-import seam as `app_install`.
///
/// Everything here answers "nothing happened" off the web, so callers never
/// need a `kIsWeb` check of their own.
abstract final class WebPush {
  static PushPermission permission() => resolvePushPermission();

  /// Prompts, then subscribes. Returns the subscription as raw JSON, or
  /// `null` if it did not happen — a refused prompt, an unsupported
  /// browser, or a push service that declined.
  ///
  /// Must be called from a user gesture: browsers refuse a permission
  /// prompt that no tap asked for.
  static Future<String?> subscribe(String vapidPublicKey) =>
      runPushSubscribe(vapidPublicKey);

  /// The existing subscription, without prompting.
  static Future<String?> current() => readPushSubscription();

  /// Unsubscribes this browser. Returns what was removed, so the caller can
  /// tell the server which endpoint to forget.
  static Future<String?> unsubscribe() => runPushUnsubscribe();
}
