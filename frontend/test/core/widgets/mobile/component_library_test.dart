// Phase Mobile M3 — the component library's own rules.
//
// These components are shared by every screen M4 will rebuild, so a defect
// here is a defect everywhere. The cases below are the ones that already bit
// once or would be invisible until a real screen hit them.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/navigation/app_branches.dart';
import 'package:sport_x_hub/core/theme/app_theme.dart';
import 'package:sport_x_hub/core/widgets/mobile/app_sheet.dart';
import 'package:sport_x_hub/core/widgets/mobile/inset_grouped_list.dart';
import 'package:sport_x_hub/l10n/generated/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  TextDirection direction = TextDirection.rtl,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.compact(AppTheme.dark),
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('AppListRow', () {
    testWidgets('a long value does not overflow the row', (tester) async {
      // The regression that shipped with the first cut of this widget: an
      // Expanded label beside an unconstrained value overflowed the moment
      // the value was something real, like an account's email address.
      await _pump(
        tester,
        const InsetGroupedList(
          children: [
            AppListRow(
              icon: Icons.alternate_email,
              label: 'البريد الإلكتروني',
              value: 'a.very.long.address.someone.uses@a-long-domain.example',
            ),
          ],
        ),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a navigating row gets a chevron', (tester) async {
      await _pump(
        tester,
        InsetGroupedList(
          children: [
            AppListRow(icon: Icons.lock_outline, label: 'Open', onTap: () {}),
          ],
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('a row that acts in place does not', (tester) async {
      // A chevron promises a screen. Log out and a toggle never open one, and
      // a row that lies about that is worse than a row with no affordance.
      await _pump(
        tester,
        InsetGroupedList(
          children: [
            AppListRow(
              icon: Icons.logout_outlined,
              label: 'Log out',
              destructive: true,
              onTap: () {},
            ),
            AppListRow(
              icon: Icons.language,
              label: 'Language',
              value: 'العربية',
              showChevron: false,
              onTap: () {},
            ),
            AppListRow(
              icon: Icons.dark_mode_outlined,
              label: 'Dark mode',
              trailing: Switch(value: true, onChanged: (_) {}),
              onTap: () {},
            ),
            const AppListRow(icon: Icons.info_outline, label: 'Just a label'),
          ],
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('a destructive row colors its label, not just its icon', (
      tester,
    ) async {
      await _pump(
        tester,
        InsetGroupedList(
          children: [
            AppListRow(
              icon: Icons.logout_outlined,
              label: 'Log out',
              destructive: true,
              onTap: () {},
            ),
          ],
        ),
      );

      final context = tester.element(find.text('Log out'));
      expect(
        tester.widget<Text>(find.text('Log out')).style?.color,
        Theme.of(context).colorScheme.error,
      );
    });

    testWidgets('rows can paint an ink splash', (tester) async {
      // The group wraps its rows in a Material rather than a DecoratedBox
      // precisely so taps produce visible feedback — the defect this app
      // already has on the Player Profile.
      await _pump(
        tester,
        InsetGroupedList(
          children: [
            AppListRow(icon: Icons.lock_outline, label: 'Row', onTap: () {}),
          ],
        ),
      );

      final inkWell = find.byType(InkWell);
      expect(inkWell, findsOneWidget);
      expect(
        find.ancestor(of: inkWell, matching: find.byType(Material)),
        findsWidgets,
      );
    });
  });

  group('InsetGroupedList', () {
    testWidgets('separates rows but does not top-and-tail them', (
      tester,
    ) async {
      // n rows means n-1 seams. A divider above the first or below the last
      // would draw a line against the card's own rounded edge.
      await _pump(
        tester,
        const InsetGroupedList(
          children: [
            AppListRow(icon: Icons.abc, label: 'One'),
            AppListRow(icon: Icons.abc, label: 'Two'),
            AppListRow(icon: Icons.abc, label: 'Three'),
          ],
        ),
      );

      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('an empty group renders nothing at all', (tester) async {
      await _pump(tester, const InsetGroupedList(children: []));
      expect(find.byType(Divider), findsNothing);
      expect(find.byType(Material), findsWidgets); // the Scaffold's own
    });
  });

  group('AppSheet', () {
    testWidgets('opens with a drag handle and clears the keyboard', (
      tester,
    ) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AppSheet.show<void>(
              context: context,
              title: 'A sheet',
              builder: (_) => const Text('SHEET_BODY'),
            ),
            child: const Text('OPEN'),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('A sheet'), findsOneWidget);
      expect(find.text('SHEET_BODY'), findsOneWidget);
      // showDragHandle inserts one; its absence is what made the old sheets
      // look like panels rather than sheets.
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('returns the value its content pops with', (tester) async {
      String? result;

      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AppSheet.show<String>(
                context: context,
                builder: (sheetContext) => TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop('picked'),
                  child: const Text('PICK'),
                ),
              );
            },
            child: const Text('OPEN'),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PICK'));
      await tester.pumpAndSettle();

      expect(result, 'picked');
    });
  });

  group('route metadata', () {
    test('a screen that owns its chrome still declares a title', () {
      // ownsChrome means the shell stands down and AppScaffoldMobile draws
      // the bar — from this same metadata. No title here is a blank bar.
      for (final branch in AppBranch.values) {
        final meta = routeMetaFor(branch.rootPath)!;
        if (!meta.ownsChrome) continue;
        expect(
          meta.title,
          isNotNull,
          reason: '${branch.rootPath} owns its chrome but has no title',
        );
      }
    });
  });
}
