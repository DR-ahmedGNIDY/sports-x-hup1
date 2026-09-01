import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../core/widgets/mobile/app_skeleton_list.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/club_profile_controller.dart';
import '../shared/club_info_section.dart';
import '../shared/club_logo_section.dart';

class EditClubProfilePageMobile extends ConsumerWidget {
  const EditClubProfilePageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clubProfileControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffoldMobile(
      // Back to the profile is the bar's own (declared in AppRouteMeta);
      // Preview is a second, different intent — see the club profile you are
      // editing — so it stays, as the bar's one action.
      actions: [
        IconButton(
          tooltip: l10n.previewLabel,
          onPressed: () => context.go('/club/preview'),
          icon: const Icon(Icons.visibility_outlined),
        ),
      ],
      slivers: [
        profileAsync.when(
          data: (_) => SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: const [
                ClubLogoSection(),
                SizedBox(height: AppSpacing.xl),
                ClubInfoSection(),
              ],
            ),
          ),
          loading: () => const SliverToBoxAdapter(
            child: AppSkeletonList(itemCount: 3, itemHeight: 160),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              onRetry: () => ref.invalidate(clubProfileControllerProvider),
            ),
          ),
        ),
      ],
    );
  }
}
