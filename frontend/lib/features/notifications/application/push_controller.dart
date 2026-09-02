import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_install.dart';
import '../data/push/web_push.dart';
import '../data/repositories/notifications_repository_impl.dart';

/// What this device can be offered, all things considered.
enum PushOffer {
  /// Permission has not been answered and the server can deliver: worth
  /// asking, at the right moment.
  canAsk,

  /// Already subscribed. Nothing to offer.
  enabled,

  /// Refused. Browsers make re-asking deliberately hard, so the app must
  /// not keep pestering — there is nothing useful to show.
  denied,

  /// iOS Safari outside an installed app. Push genuinely cannot work here,
  /// but installing to the Home Screen makes it work — the one "no" that
  /// deserves an explanation rather than silence.
  needsInstall,

  /// No push at all, or the server has no VAPID keys. Say nothing.
  unavailable,
}

class PushController {
  PushController(this._ref);

  final Ref _ref;

  /// Works out what to offer without prompting for anything.
  ///
  /// The server is asked *first*: a browser gives one permission prompt,
  /// effectively forever, and spending it on a backend with no VAPID keys
  /// would burn it for nothing.
  Future<PushOffer> offer() async {
    final permission = WebPush.permission();

    if (permission == PushPermission.unsupported) {
      // The iPhone case, which is the one that will otherwise generate
      // support questions: Safari grants push only to an installed PWA, and
      // nothing in the browser explains that.
      return installOffer() == InstallOffer.none
          ? PushOffer.unavailable
          : PushOffer.needsInstall;
    }
    if (permission == PushPermission.denied) return PushOffer.denied;

    final String? key;
    try {
      key = await _ref.read(notificationsRepositoryProvider).pushPublicKey();
    } on AppException {
      return PushOffer.unavailable;
    }
    if (key == null) return PushOffer.unavailable;

    if (permission == PushPermission.granted) {
      // Granted, but this browser may still have no live subscription — a
      // cleared profile or a rotated key drops it silently. Re-register
      // rather than assuming.
      final existing = await WebPush.current();
      if (existing == null) return PushOffer.canAsk;
      await _register(existing);
      return PushOffer.enabled;
    }
    return PushOffer.canAsk;
  }

  /// Prompts and registers. Returns whether this device will now be pushed
  /// to.
  ///
  /// Must be called straight from a tap: browsers refuse a permission
  /// prompt that no gesture asked for.
  Future<bool> enable() async {
    final repository = _ref.read(notificationsRepositoryProvider);
    final String? key;
    try {
      key = await repository.pushPublicKey();
    } on AppException {
      return false;
    }
    if (key == null) return false;

    final subscription = await WebPush.subscribe(key);
    if (subscription == null) return false;
    return _register(subscription);
  }

  Future<bool> disable() async {
    final removed = await WebPush.unsubscribe();
    if (removed == null) return false;
    final endpoint = _decode(removed)?['endpoint'];
    if (endpoint is! String) return false;
    try {
      await _ref
          .read(notificationsRepositoryProvider)
          .unsubscribePush(endpoint);
      return true;
    } on AppException {
      // The browser has already unsubscribed, so no more banners arrive
      // either way; the server row is pruned on its next failed send.
      return true;
    }
  }

  Future<bool> _register(String subscriptionJson) async {
    final subscription = _decode(subscriptionJson);
    if (subscription == null) return false;
    try {
      await _ref
          .read(notificationsRepositoryProvider)
          .subscribePush(subscription);
      return true;
    } on AppException {
      return false;
    }
  }

  Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

final pushControllerProvider = Provider<PushController>(
  (ref) => PushController(ref),
);

/// What to offer on this device, resolved once per session.
final pushOfferProvider = FutureProvider<PushOffer>(
  (ref) => ref.read(pushControllerProvider).offer(),
);
