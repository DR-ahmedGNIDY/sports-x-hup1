import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../core/widgets/mobile/app_skeleton_list.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_profile_controller.dart';
import '../shared/share_profile_button.dart';
import 'player_profile_scouting_layout_mobile.dart';

class MyProfilePreviewPageMobile extends ConsumerWidget {
  const MyProfilePreviewPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffoldMobile(
      // The profile family runs on its own darker palette; the bar takes its
      // tint from the same value so the two read as one sheet.
      background: context.profileColors.bg,
      onRefresh: () =>
          ref.read(playerProfileControllerProvider.notifier).refresh(),
      slivers: [
        profileAsync.when(
          data: (profile) => SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: PlayerProfileScoutingLayoutMobile(
                profile: profile,
                showContact: true,
                isOwner: true,
                heroActions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeroActionButton(
                      icon: Icons.edit_outlined,
                      label: l10n.dashboardEditProfile,
                      onPressed: () => context.go('/player/edit'),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    ShareProfileButton(playerId: profile.id, compact: true),
                  ],
                ),
              ),
            ),
          ),
          loading: () => const SliverToBoxAdapter(
            child: AppSkeletonList(itemCount: 4, itemHeight: 140),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              onRetry: () =>
                  ref.read(playerProfileControllerProvider.notifier).refresh(),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small pill action button for the Hero Card's action slot — same
/// role as the old page-header `IconButton`, just styled to sit on the
/// hero's dark/glow background instead of a plain app bar.
class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = context.profileColors.accent;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: accent),
      label: Text(label, style: TextStyle(color: accent, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: accent.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
    );
  }
}
