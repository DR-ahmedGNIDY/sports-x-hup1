import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/notifications_repository_impl.dart';
import 'notifications_controller.dart';

/// Push for the Android app, through Firebase Cloud Messaging.
///
/// The web build keeps using Web Push (see [PushController]); this class is
/// a no-op everywhere except a native Android build. The server renders the
/// banner text, so Android shows it from the tray even with the app closed —
/// nothing here has to run for a notification to appear.
class NativePush {
  NativePush(this._ref);

  final Ref _ref;
  bool _listening = false;
  String? _token;

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Called once at startup, before runApp. Never throws: a phone where
  /// Firebase cannot start must still open the app.
  static Future<void> initialize() async {
    if (!supported) return;
    try {
      await Firebase.initializeApp();
    } catch (error) {
      debugPrint('Firebase init failed: $error');
    }
  }

  /// After sign-in: ask for permission (Android 13+ shows a prompt), then
  /// tell the server which phone this account is on.
  Future<void> start(GoRouter router) async {
    if (!supported || Firebase.apps.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) await _register(token);

      if (_listening) return;
      _listening = true;
      messaging.onTokenRefresh.listen(_register);
      // App open: Android shows no banner, so at least refresh the bell.
      FirebaseMessaging.onMessage.listen(
        (_) => _ref.invalidate(unreadNotificationsProvider),
      );
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(router, m));
      final initial = await messaging.getInitialMessage();
      if (initial != null) _open(router, initial);
    } catch (error) {
      debugPrint('FCM start failed: $error');
    }
  }

  /// Before sign-out, so the next account on this phone doesn't receive the
  /// previous one's notifications.
  Future<void> stop() async {
    final token = _token;
    if (!supported || token == null) return;
    _token = null;
    try {
      await _ref
          .read(notificationsRepositoryProvider)
          .unregisterDevice(token)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best effort — the token is re-pointed on the next sign-in anyway.
    }
  }

  Future<void> _register(String token) async {
    _token = token;
    try {
      await _ref.read(notificationsRepositoryProvider).registerDevice(token);
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  void _open(GoRouter router, RemoteMessage message) {
    final path = message.data['path'];
    router.go(path is String && path.startsWith('/') ? path : '/notifications');
  }
}

final nativePushProvider = Provider<NativePush>((ref) => NativePush(ref));
