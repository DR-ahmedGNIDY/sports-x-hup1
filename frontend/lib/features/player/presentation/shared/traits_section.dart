import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../videos/application/player_traits_provider.dart';
import '../../../videos/domain/entities/player_traits.dart';

/// Football-only "Traits" section — one rating bar (0-99, like a game
/// attribute) per skill category, entirely derived from the player's own
/// uploaded videos: see `myTraitsProvider`/`playerTraitsProvider`. Read-only
/// by design — there's nothing here for the player or a viewer to edit.
class TraitsSection extends ConsumerWidget {
  const TraitsSection({super.key, required this.isOwner, required this.playerId});

  final bool isOwner;
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final traitsAsync = isOwner
        ? ref.watch(myTraitsProvider)
        : ref.watch(playerTraitsProvider(playerId));

    return traitsAsync.when(
      data: (traits) {
        if (traits == null || traits.traits.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.traitsCaption,
              style: const TextStyle(color: AppColors.greyLight, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final trait in traits.traits) ...[
              _TraitBar(trait: trait),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _TraitBar extends StatelessWidget {
  const _TraitBar({required this.trait});

  final PlayerTrait trait;

  @override
  Widget build(BuildContext context) {
    final displayScore = trait.score.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                trait.category,
                style: const TextStyle(
                  color: AppColors.profileText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$displayScore',
              style: const TextStyle(
                color: AppColors.profileAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: trait.score / 99,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation(AppColors.profileAccent),
          ),
        ),
      ],
    );
  }
}
