import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Small colored completeness badge for a single managed player — "100%
/// Complete" (success) or "N% Complete" (primary tint) — used by both the
/// Desktop roster table's Status column and the Mobile roster card. Renders
/// nothing when [percent] is `null` (a view that doesn't carry it) rather
/// than showing a fabricated value.
class ClubPlayerCompletenessChip extends StatelessWidget {
  const ClubPlayerCompletenessChip({super.key, required this.percent});

  final int? percent;

  @override
  Widget build(BuildContext context) {
    final value = percent;
    if (value == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final isComplete = value >= 100;
    final tint = isComplete ? AppColors.success : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        isComplete
            ? l10n.clubPlayerProfileCompleteLabel
            : l10n.clubPlayerProfilePercentCompleteLabel(value),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: tint, fontWeight: FontWeight.w600),
      ),
    );
  }
}
