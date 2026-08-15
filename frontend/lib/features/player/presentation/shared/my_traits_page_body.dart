import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/profile_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_profile_controller.dart';
import 'traits_section.dart';

/// Standalone "Traits" screen body — reachable directly from the mobile
/// bottom nav. Football-only (see [TraitsSection]); every other sport gets
/// a short explanatory message instead of an empty screen.
class MyTraitsPageBody extends ConsumerWidget {
  const MyTraitsPageBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final profileColors = context.profileColors;

    return profileAsync.when(
      data: (profile) {
        if (profile.sport != 'Football') {
          return Center(
            child: Text(
              l10n.traitsFootballOnlyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: profileColors.textMuted),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.traitsTitle,
              style: TextStyle(
                color: profileColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TraitsSection(isOwner: true, playerId: profile.id),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        onRetry: () => ref.read(playerProfileControllerProvider.notifier).refresh(),
      ),
    );
  }
}
