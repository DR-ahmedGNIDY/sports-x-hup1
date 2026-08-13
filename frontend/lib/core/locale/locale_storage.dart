import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the chosen app language across app restarts — same rationale
/// and pattern as SessionStorage (core/storage/session_storage.dart):
/// constructor-injected SharedPreferences, one key, read/write only.
class LocaleStorage {
  LocaleStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _localeKey = 'sxh_locale';

  Locale? get locale {
    final code = _prefs.getString(_localeKey);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale locale) => _prefs.setString(_localeKey, locale.languageCode);
}
