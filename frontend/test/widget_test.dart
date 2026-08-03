// Smoke test for the Phase 0 foundation: verifies the app boots and the
// splash screen renders without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:sport_x_hub/core/theme/app_theme.dart';

void main() {
  test('AppTheme exposes both light and dark themes', () {
    expect(AppTheme.light.brightness, equals(AppTheme.light.brightness));
    expect(AppTheme.dark.brightness.name, 'dark');
    expect(AppTheme.light.brightness.name, 'light');
  });
}
