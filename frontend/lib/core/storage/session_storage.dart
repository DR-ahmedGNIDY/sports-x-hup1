import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT access/refresh token pair across app restarts.
///
/// Tokens live in `flutter_secure_storage` (Keychain on iOS/macOS,
/// EncryptedSharedPreferences/Keystore on Android, DPAPI on Windows) rather
/// than plain SharedPreferences. On Web, `flutter_secure_storage` still
/// resolves to `window.localStorage` under the hood — there's no OS-level
/// keystore a browser page can use — so this buys real protection only on
/// native builds (chiefly Android, the build this project actually ships
/// to app stores); it's used everywhere anyway so there's one code path
/// rather than a Web/native split, and it's strictly no worse than the
/// previous SharedPreferences-only approach on Web.
///
/// [migrateFromSharedPreferences] moves any token pair written by the old
/// SharedPreferences-based implementation into secure storage once, then
/// deletes the plaintext copy — existing installs are upgraded in place
/// rather than being forced to log out.
class SessionStorage {
  SessionStorage(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const _accessTokenKey = 'sxh_access_token';
  static const _refreshTokenKey = 'sxh_refresh_token';

  Future<String?> get accessToken => _secureStorage.read(key: _accessTokenKey);

  Future<String?> get refreshToken =>
      _secureStorage.read(key: _refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  /// One-time upgrade path from the previous SharedPreferences-backed
  /// storage. Safe to call unconditionally on every app start: it's a
  /// no-op once the plaintext keys are gone.
  Future<void> migrateFromSharedPreferences(SharedPreferences prefs) async {
    final legacyAccessToken = prefs.getString(_accessTokenKey);
    final legacyRefreshToken = prefs.getString(_refreshTokenKey);
    if (legacyAccessToken == null && legacyRefreshToken == null) return;

    if (legacyAccessToken != null) {
      await _secureStorage.write(
        key: _accessTokenKey,
        value: legacyAccessToken,
      );
    }
    if (legacyRefreshToken != null) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: legacyRefreshToken,
      );
    }
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
