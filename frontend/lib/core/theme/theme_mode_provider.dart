import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide dark/light mode toggle. Defaults to following the OS setting.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Shared so Desktop and Mobile presentation trees don't each re-derive the
/// same icon-for-mode decision independently.
IconData themeModeToggleIcon(ThemeMode mode) =>
    mode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
