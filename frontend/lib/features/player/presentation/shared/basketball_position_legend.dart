import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The current / alternate / other legend row shown under the court —
/// color alone never carries the meaning (see the check/border cues on
/// the markers themselves), this just spells it out.
class BasketballPositionLegend extends StatelessWidget {
  const BasketballPositionLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileColors = context.profileColors;
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        _LegendItem(color: AppColors.pitchPrimary, label: l10n.basketballPositionPrimaryLabel),
        _LegendItem(color: AppColors.success, label: l10n.basketballPositionSecondaryLabel),
        _LegendItem(color: profileColors.neutralBadgeBg, label: l10n.basketballPositionOtherLabel),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final profileColors = context.profileColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: profileColors.borderOnSurface.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, style: TextStyle(color: profileColors.textMuted, fontSize: 13)),
        ),
      ],
    );
  }
}
