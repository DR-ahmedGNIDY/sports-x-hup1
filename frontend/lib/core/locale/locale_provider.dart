import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_storage_provider.dart';

const arabicLocale = Locale('ar');
const englishLocale = Locale('en');

/// App-wide language. Arabic is the primary/default language regardless of
/// device locale (per product decision); a stored choice (LocaleStorage)
/// overrides the default on subsequent launches. Same shape as
/// ThemeModeController (core/theme/theme_mode_provider.dart), except the
/// choice is persisted — losing a deliberate language choice on reload is a
/// worse regression than losing a theme choice, so unlike theme this reads
/// its initial value from storage instead of a fixed default.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => ref.read(localeStorageProvider).locale ?? arabicLocale;

  void toggle() => set(state == arabicLocale ? englishLocale : arabicLocale);

  void set(Locale locale) {
    state = locale;
    ref.read(localeStorageProvider).setLocale(locale);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
