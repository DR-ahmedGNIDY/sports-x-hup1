import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../home_feed/presentation/mobile/home_feed_page_mobile.dart';
import '../../../home_feed/presentation/shared/create_post_sheet.dart';

/// Content-only — the top bar/bottom nav chrome that used to live here now
/// lives in `AppShell` (mounted once by the `/dashboard` ShellRoute), so
/// this widget is just the Player/Club/Admin dashboard body.
class DashboardPageMobile extends ConsumerWidget {
  const DashboardPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final l10n = AppLocalizations.of(context)!;
    final roleLabel = switch (user?.role) {
      UserRole.club => l10n.roleClub,
      UserRole.admin => l10n.dashboardRoleAdmin,
      _ => l10n.rolePlayer,
    };
    return _DashboardBody(role: user?.role, roleLabel: roleLabel);
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.role, required this.roleLabel});

  final UserRole? role;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Player's Home content used to live here (profile completion, stats,
    // quick actions) — it moved to the Player Profile page (see
    // OwnerAccountSection); Home itself is now the activity feed.
    if (role == UserRole.player) {
      return const HomeFeedPageMobile();
    }
    if (role == UserRole.club) {
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
    if (role == UserRole.admin) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.dashboardTitleWithRole(l10n.dashboardRoleAdmin)),
            const SizedBox(height: 8),
            Text(l10n.dashboardAdminMobileHint),
          ],
        ),
      );
    }
    return Center(child: Text(l10n.dashboardComingSoon(roleLabel)));
  }
}
