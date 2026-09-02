import 'dart:js_interop';

import 'web_push.dart';

/// The browser half lives in `web/index.html`, for the same reason the
/// install prompt's does: these are a handful of calls whose shapes are
/// awkward to bind through js_interop, and each one answers with a plain
/// string a single `external` declaration can read.
@JS('sxhPushPermission')
external JSFunction? get _permission;

@JS('sxhSubscribePush')
external JSFunction? get _subscribe;

@JS('sxhCurrentPushSubscription')
external JSFunction? get _current;

@JS('sxhUnsubscribePush')
external JSFunction? get _unsubscribe;

PushPermission resolvePushPermission() {
  final fn = _permission;
  if (fn == null) return PushPermission.unsupported;
  return switch (fn.callAsFunction()?.dartify()) {
    'granted' => PushPermission.granted,
    'denied' => PushPermission.denied,
    'default' => PushPermission.prompt,
    // Includes 'unsupported' and anything unexpected: treated as "cannot",
    // which is the safe direction — it hides an affordance rather than
    // offering one that will not work.
    _ => PushPermission.unsupported,
  };
}

Future<String?> runPushSubscribe(String vapidPublicKey) =>
    _awaitString(_subscribe, vapidPublicKey.toJS);

Future<String?> readPushSubscription() => _awaitString(_current);

Future<String?> runPushUnsubscribe() => _awaitString(_unsubscribe);

/// Every one of these resolves to a JSON string, or `''` for "did not
/// happen" — normalized to `null` here so callers test one thing.
Future<String?> _awaitString(JSFunction? fn, [JSAny? argument]) async {
  if (fn == null) return null;
  final result = argument == null
      ? fn.callAsFunction()
      : fn.callAsFunction(null, argument);
  if (result == null) return null;
  if (result.isA<JSPromise>()) {
    final resolved = await (result as JSPromise).toDart;
    final value = resolved.dartify();
    return (value is String && value.isNotEmpty) ? value : null;
  }
  final value = result.dartify();
  return (value is String && value.isNotEmpty) ? value : null;
}
