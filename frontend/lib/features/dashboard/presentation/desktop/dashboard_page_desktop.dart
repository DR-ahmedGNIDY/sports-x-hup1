import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../home_feed/presentation/desktop/home_feed_page_desktop.dart';
import '../../../home_feed/presentation/shared/create_post_sheet.dart';

/// Content-only — the sidebar/top bar chrome that used to live here now
/// lives in `AppShell` (mounted once by the `/dashboard` ShellRoute), so
/// this widget is just the Player/Club/Admin dashboard body.
class DashboardPageDesktop extends ConsumerWidget {
  const DashboardPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final l10n = AppLocalizations.of(context)!;
    final roleLabel = switch (user?.role) {
      UserRole.club => l10n.roleClub,
      UserRole.admin => l10n.dashboardRoleAdmin,
      _ => l10n.rolePlayer,
    };

    // Player's Home content used to live here (profile completion, stats,
    // quick actions) — it moved to the Player Profile page (see
    // OwnerAccountSection); Home itself is now the activity feed.
    if (user?.role == UserRole.player) {
      return const HomeFeedPageDesktop();
    }
    if (user?.role == UserRole.club) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.dashboardTitleWithRole(roleLabel)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/search'),
              icon: const Icon(Icons.search_outlined),
              label: Text(l10n.dashboardSearchPlayers),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go('/saved-players'),
              icon: const Icon(Icons.bookmark_outline),
              label: Text(l10n.dashboardSavedPlayers),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go('/club/players'),
              icon: const Icon(Icons.groups_outlined),
              label: const Text('لاعبو النادي'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go('/club/preview'),
              icon: const Icon(Icons.shield_outlined),
              label: Text(l10n.dashboardMyClub),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => CreatePostSheet.show(context, role: UserRole.club),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l10n.homeFeedNewPostTitle),
            ),
          ],
        ),
      );
    }
    return Center(child: Text(l10n.dashboardComingSoon(roleLabel)));
  }
}
