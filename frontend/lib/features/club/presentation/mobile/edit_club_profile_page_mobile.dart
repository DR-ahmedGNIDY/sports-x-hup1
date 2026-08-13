import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
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

    return profileAsync.when(
      data: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.dashboardEditClubProfile, style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                tooltip: l10n.previewLabel,
                onPressed: () => context.go('/club/preview'),
                icon: const Icon(Icons.visibility_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const ClubLogoSection(),
          const SizedBox(height: 24),
          const ClubInfoSection(),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(clubProfileControllerProvider)),
    );
  }
}
