import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../locale/locale_storage.dart';
import '../locale/locale_storage_provider.dart';

/// App-wide dark/light mode toggle. Defaults to dark regardless of the OS
/// setting — the site's primary look — and remembers the person's choice
/// across reloads, beside their language.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() =>
      _storage()?.themeMode == 'light' ? ThemeMode.light : ThemeMode.dark;

  void toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  void set(ThemeMode mode) {
    state = mode;
    _storage()?.setThemeMode(mode == ThemeMode.light ? 'light' : 'dark');
  }

  /// Null where storage was never wired (some widget tests): the toggle
  /// still works, it just is not remembered.
  LocaleStorage? _storage() {
    try {
      return ref.read(localeStorageProvider);
    } catch (_) {
      return null;
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Shared so Desktop and Mobile presentation trees don't each re-derive the
/// same icon-for-mode decision independently.
IconData themeModeToggleIcon(ThemeMode mode) => mode == ThemeMode.dark
    ? Icons.light_mode_outlined
    : Icons.dark_mode_outlined;
