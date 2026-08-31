// Phase Mobile M2 — the invariants the shell's navigation silently depends
// on. `StatefulNavigationShell.currentIndex` is an integer into the router's
// branch list, and the shell turns that integer back into an AppBranch. If
// the two orders ever disagree the app doesn't crash, it just quietly shows
// the wrong tab as selected — which is exactly the kind of bug that survives
// review, so it's pinned here instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/navigation/app_branches.dart';
import 'package:sport_x_hub/features/auth/domain/entities/user_role.dart';

void main() {
  group('AppBranch', () {
    test('every branch has a unique root path', () {
      final paths = AppBranch.values.map((b) => b.rootPath).toList();
      expect(paths.toSet(), hasLength(paths.length));
    });

    test('every root path has route metadata', () {
      for (final branch in AppBranch.values) {
        expect(
          routeMetaFor(branch.rootPath),
          isNotNull,
          reason: '${branch.name} would show a blank app bar',
        );
      }
    });

    test('selected and unselected icons differ', () {
      for (final branch in AppBranch.values) {
        expect(
          branch.selectedIcon,
          isNot(branch.icon),
          reason: '${branch.name} would not read as selected',
        );
      }
    });
  });

  group('routeMetaFor', () {
    test('only Home shows the logo instead of a title', () {
      final untitled = [
        for (final branch in AppBranch.values)
          if (routeMetaFor(branch.rootPath)!.title == null) branch,
      ];
      expect(untitled, [AppBranch.home]);
    });

    test('a detail route declares where back goes', () {
      for (final path in [
        '/player/edit',
        '/player/traits',
        '/club/edit',
        '/club/players/new',
        '/club/players/abc123/edit',
      ]) {
        final meta = routeMetaFor(path);
        expect(meta, isNotNull, reason: path);
        expect(meta!.parentPath, isNotNull, reason: '$path has no way back');
        expect(
          routeMetaFor(meta.parentPath!),
          isNotNull,
          reason: '$path points back at a route with no metadata',
        );
      }
    });

    test('a branch root has no back button', () {
      for (final branch in AppBranch.values) {
        expect(routeMetaFor(branch.rootPath)!.parentPath, isNull);
      }
    });

    test('an unknown or marketing path has no metadata', () {
      for (final path in ['/home', '/login', '/players/abc', '/nope']) {
        expect(routeMetaFor(path), isNull, reason: path);
      }
    });
  });

  group('tabs', () {
    test('no role gets more than four tabs beside the account slot', () {
      // Five slots is the ceiling before labels start truncating at 320px.
      for (final role in [...UserRole.values, null]) {
        expect(
          tabBranchesFor(role).length,
          lessThanOrEqualTo(4),
          reason: '$role',
        );
      }
    });

    test('every role can reach Home and Settings', () {
      for (final role in [...UserRole.values, null]) {
        final reachable = [
          ...tabBranchesFor(role),
          ...overflowBranchesFor(role),
        ];
        expect(reachable, contains(AppBranch.home), reason: '$role');
        expect(reachable, contains(AppBranch.settings), reason: '$role');
      }
    });

    test('a branch is never both a tab and an account-sheet entry', () {
      for (final role in [...UserRole.values, null]) {
        final tabs = tabBranchesFor(role);
        for (final branch in overflowBranchesFor(role)) {
          expect(tabs, isNot(contains(branch)), reason: '$role / ${branch.name}');
        }
      }
    });

    test('a Club reaches its own screens, an Admin reaches admin tooling', () {
      final club = tabBranchesFor(UserRole.club);
      expect(club, containsAll([AppBranch.clubProfile, AppBranch.clubPlayers]));
      expect(
        overflowBranchesFor(UserRole.admin),
        contains(AppBranch.adminUsers),
      );
      // Admin tooling must not leak into a Player's navigation.
      expect(
        [
          ...tabBranchesFor(UserRole.player),
          ...overflowBranchesFor(UserRole.player),
        ],
        isNot(contains(AppBranch.adminUsers)),
      );
    });
  });
}
