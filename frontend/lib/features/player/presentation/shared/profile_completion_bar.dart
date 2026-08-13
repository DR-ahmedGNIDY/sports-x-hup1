import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_stats_controller.dart';

/// Thin completion indicator for the top of Edit Profile — lets the player
/// see the effect of filling in a field without leaving the form (the
/// Dashboard's completion card has the full missing-fields checklist).
/// Renders nothing while loading or on error since it's a supporting
/// decoration, not the page's primary content.
class ProfileCompletionBar extends ConsumerWidget {
  const ProfileCompletionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatsControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return statsAsync.maybeWhen(
      data: (stats) {
        final colorScheme = Theme.of(context).colorScheme;
        final progressColor = stats.isComplete ? AppColors.success : colorScheme.primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: stats.completionPercent / 100,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: progressColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.profileCompletionLabel(stats.completionPercent),
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: progressColor),
                  ),
                ],
              ),
              if (!stats.isComplete) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.fieldsRemainingHint(stats.missingFields.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
