import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT access/refresh token pair across app restarts.
///
/// Tokens live in SharedPreferences (browser localStorage on Web, native
/// prefs on Android) rather than flutter_secure_storage: on Web the two are
/// equally JS-accessible — secure storage buys no real protection there —
/// and this keeps the MVP to one storage dependency. Revisit if/when a
/// stricter threat model calls for httpOnly cookies or native secure
/// storage specifically for the Android build.
class SessionStorage {
  SessionStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _accessTokenKey = 'sxh_access_token';
  static const _refreshTokenKey = 'sxh_refresh_token';

  String? get accessToken => _prefs.getString(_accessTokenKey);

  String? get refreshToken => _prefs.getString(_refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clear() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }
}
