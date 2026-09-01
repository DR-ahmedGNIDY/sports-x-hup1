// Phase Mobile M8 — the accessibility properties the mobile work has to hold
// up under, exercised at the sizes and settings a real user can choose.
//
// These are deliberately about *the app's own* chrome and components. The
// point is not to assert that Flutter's widgets work; it is that the ones
// this effort built keep working when someone doubles their text size, turns
// their phone to Arabic, or reaches for a 320px screen.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/core/theme/app_touch.dart';
import 'package:sport_x_hub/core/widgets/mobile/app_empty_state.dart';
import 'package:sport_x_hub/core/widgets/mobile/inset_grouped_list.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

/// The device matrix from the plan: the smallest phone still in use up to a
/// large one.
const _phones = <String, Size>{
  'iPhone SE': Size(375, 667),
  'small Android': Size(320, 640),
  'iPhone 15 Pro': Size(393, 852),
  'Pixel 8': Size(412, 915),
};

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
  Brightness brightness = Brightness.dark,
  TextDirection direction = TextDirection.rtl,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final base = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.compact(base),
      locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: widget!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
}

Widget _settingsGroup() => const InsetGroupedList(
  header: 'الحساب',
  children: [
    AppListRow(
      icon: Icons.alternate_email,
      label: 'البريد الإلكتروني',
      value: 'someone@example.test',
    ),
    AppListRow(icon: Icons.lock_outline, label: 'تغيير كلمة المرور'),
    AppListRow(
      icon: Icons.logout_outlined,
      label: 'تسجيل الخروج',
      destructive: true,
    ),
  ],
);

void main() {
  group('text scaling', () {
    // Someone who has doubled their system text size is exactly the person
    // most likely to be reading an app in a language whose script is already
    // dense. 2.0 is the ceiling both platforms expose.
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('a settings group survives ${scale}x text', (tester) async {
        await _pump(tester, _settingsGroup(), textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('an empty state survives 2x text on the smallest phone', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppEmptyState(
          message: 'لم تحفظ أي لاعبين بعد.',
          actionLabel: 'البحث عن اللاعبين',
        ),
        size: const Size(320, 640),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('device matrix', () {
    _phones.forEach((name, size) {
      testWidgets('a settings group lays out on $name', (tester) async {
        await _pump(tester, _settingsGroup(), size: size);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('direction and theme', () {
    for (final direction in TextDirection.values) {
      for (final brightness in Brightness.values) {
        testWidgets('a settings group renders in $direction / $brightness', (
          tester,
        ) async {
          await _pump(
            tester,
            _settingsGroup(),
            direction: direction,
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('rows mirror: the icon leads in both directions', (
      tester,
    ) async {
      // A row's icon belongs at the reading start. Hardcoding it left would
      // put it at the *end* of every Arabic row, which is the app's default
      // language.
      await _pump(tester, _settingsGroup(), direction: TextDirection.ltr);
      final ltrIcon = tester.getCenter(find.byIcon(Icons.alternate_email)).dx;
      final ltrLabel = tester.getCenter(find.text('البريد الإلكتروني')).dx;
      expect(ltrIcon, lessThan(ltrLabel));

      await _pump(tester, _settingsGroup(), direction: TextDirection.rtl);
      final rtlIcon = tester.getCenter(find.byIcon(Icons.alternate_email)).dx;
      final rtlLabel = tester.getCenter(find.text('البريد الإلكتروني')).dx;
      expect(rtlIcon, greaterThan(rtlLabel));
    });
  });

  group('screen readers', () {
    test('every IconButton in the app names itself', () {
      // An IconButton with no tooltip announces itself as "button" and
      // nothing else: the icon is invisible to a screen reader, so the
      // tooltip is the only label there is. Seventeen of them were silent.
      //
      // A source scan rather than a widget test on purpose — the point is
      // coverage across all ~48 of them, and no widget test mounts every
      // screen they live on.
      final offenders = <String>[];
      final iconButton = RegExp(r'IconButton\(');

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();

        for (final match in iconButton.allMatches(source)) {
          // The button's own arguments end at its closing paren; nesting is
          // shallow enough here that scanning to the next `IconButton(` or a
          // generous window is both simpler and sufficient.
          final start = match.end;
          final window = source.substring(
            start,
            (start + 400).clamp(0, source.length),
          );
          final body = window.split('IconButton(').first;
          if (!body.contains('tooltip:')) {
            final line = '\n'.allMatches(source.substring(0, start)).length + 1;
            offenders.add('${entity.path}:$line');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'These IconButtons have no tooltip, so a screen reader has no '
            'name to read:\n${offenders.join('\n')}',
      );
    });
  });

  group('touch targets', () {
    testWidgets('a tappable row clears the minimum on the smallest phone', (
      tester,
    ) async {
      await _pump(
        tester,
        InsetGroupedList(
          children: [
            AppListRow(
              icon: Icons.lock_outline,
              label: 'تغيير كلمة المرور',
              onTap: () {},
            ),
          ],
        ),
        size: const Size(320, 640),
      );

      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(AppTouch.minTarget),
      );
    });
  });
}
