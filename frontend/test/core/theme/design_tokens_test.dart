// Phase Mobile M1 — guards the token layer itself, since a design system is
// only worth anything if it stays the single source of truth.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/theme/app_colors.dart';
import 'package:sport_x_hub/core/theme/app_elevation.dart';
import 'package:sport_x_hub/core/theme/app_radius.dart';
import 'package:sport_x_hub/core/theme/app_text_styles.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/core/theme/app_touch.dart';

void main() {
  group('AppRadius', () {
    test('is a strictly ascending scale', () {
      const scale = [
        AppRadius.xxs,
        AppRadius.xs,
        AppRadius.sm,
        AppRadius.md,
        AppRadius.lg,
        AppRadius.xl,
        AppRadius.pill,
      ];
      for (var i = 1; i < scale.length; i++) {
        expect(
          scale[i],
          greaterThan(scale[i - 1]),
          reason: 'step $i (${scale[i]}) must exceed ${scale[i - 1]}',
        );
      }
    });

    test('no literal corner radius survives outside the token file', () {
      // The rule this whole layer exists to enforce: a raw `circular(12)`
      // anywhere in lib/ is drift, and drift is what produced ten different
      // radii across ~60 call sites before M1.
      final offenders = <String>[];
      final literal = RegExp(r'circular\(\s*[0-9]');

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('app_radius.dart')) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (literal.hasMatch(lines[i])) {
            offenders.add('${entity.path}:${i + 1}  ${lines[i].trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Use an AppRadius token instead of a literal radius:\n'
            '${offenders.join('\n')}',
      );
    });
  });

  group('AppElevation', () {
    test('shadow color strengthens with elevation in both brightnesses', () {
      for (final brightness in Brightness.values) {
        expect(
          AppElevation.overlay.shadowColor(brightness).a,
          greaterThan(AppElevation.raised.shadowColor(brightness).a),
          reason: '$brightness',
        );
      }
    });

    test('dark mode glows lighter than the surface, light mode darkens', () {
      // The rule the card theme was already following by hand: a black drop
      // shadow on a near-black background is invisible, so dark mode tints
      // its shadow with the light brand blue instead.
      final dark = AppElevation.raised.shadowColor(Brightness.dark);
      final light = AppElevation.raised.shadowColor(Brightness.light);

      expect(
        (dark.r, dark.g, dark.b),
        (
          AppColors.brandBlueLight.r,
          AppColors.brandBlueLight.g,
          AppColors.brandBlueLight.b,
        ),
      );
      expect(
        (light.r, light.g, light.b),
        (AppColors.black.r, AppColors.black.g, AppColors.black.b),
      );
      // And the glow really is lighter than the near-black surface it sits on.
      expect(dark.computeLuminance(), greaterThan(light.computeLuminance()));
    });
  });

  group('AppTheme.compact', () {
    test('enlarges body text without touching color or shape', () {
      final base = AppTheme.dark;
      final compact = AppTheme.compact(base);

      expect(base.textTheme.bodyMedium!.fontSize, 14);
      expect(compact.textTheme.bodyMedium!.fontSize, 16);
      expect(
        compact.textTheme.bodyMedium!.color,
        base.textTheme.bodyMedium!.color,
      );
      expect(compact.colorScheme, base.colorScheme);
      expect(compact.cardTheme.shape, base.cardTheme.shape);
    });

    test('the primary button looks the same whichever widget raised it', () {
      // FilledButton is what 31 files actually use; ElevatedButton is what
      // the theme used to style. Leaving the two unequal meant most of the
      // app's submit buttons wore Material's seeded onPrimary — dark navy on
      // brand blue — instead of the brand pairing.
      for (final theme in [AppTheme.dark, AppTheme.light]) {
        final filled = theme.filledButtonTheme.style!;
        final elevated = theme.elevatedButtonTheme.style!;

        expect(
          filled.foregroundColor?.resolve({}),
          AppColors.white,
          reason: '${theme.brightness}',
        );
        expect(
          filled.backgroundColor?.resolve({}),
          AppColors.brandBlue,
          reason: '${theme.brightness}',
        );
        expect(filled.foregroundColor, elevated.foregroundColor);
        expect(filled.backgroundColor, elevated.backgroundColor);
        expect(filled.shape, elevated.shape);
      }
    });

    test('raises text/outlined buttons to the minimum touch target', () {
      // Material sizes these at 40 tall, below AppTouch.minTarget. The base
      // theme is left alone: a 40px target is fine under a cursor, and this
      // phase is not in the business of resizing the desktop app.
      final compact = AppTheme.compact(AppTheme.dark);

      for (final style in [
        compact.textButtonTheme.style,
        compact.outlinedButtonTheme.style,
      ]) {
        final size = style!.minimumSize!.resolve({});
        expect(size!.height, AppTouch.minTarget);
      }

      expect(AppTheme.dark.textButtonTheme.style?.minimumSize, isNull);
    });

    test('every compact style is at least as large as its base', () {
      final pairs = <String, (TextStyle, TextStyle)>{
        'displayLarge': (
          AppTextStyles.displayLarge,
          AppTextStyles.compactDisplayLarge,
        ),
        'headline': (AppTextStyles.headline, AppTextStyles.compactHeadline),
        'title': (AppTextStyles.title, AppTextStyles.compactTitle),
        'body': (AppTextStyles.body, AppTextStyles.compactBody),
        'bodyStrong': (
          AppTextStyles.bodyStrong,
          AppTextStyles.compactBodyStrong,
        ),
        'caption': (AppTextStyles.caption, AppTextStyles.compactCaption),
      };

      pairs.forEach((name, pair) {
        final (base, compact) = pair;
        expect(
          compact.fontSize,
          greaterThan(base.fontSize!),
          reason: '$name should be larger on a phone',
        );
        // Sizes only — a compact style that quietly changed weight or family
        // would let the two scales drift into different typefaces.
        expect(compact.fontWeight, base.fontWeight, reason: name);
        expect(compact.fontFamily, base.fontFamily, reason: name);
      });
    });
  });
}
