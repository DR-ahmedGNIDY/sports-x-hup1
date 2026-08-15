import 'package:flutter/material.dart';

import '../../../../core/theme/profile_colors.dart';
import 'player_profile_data.dart';

/// The "Quick Stats" row right below the hero — Age / Height / Weight /
/// Preferred Foot / Birth Year, one tile per fact actually present on the
/// profile (see [buildQuickFacts] / [QuickFact] for what "present" means
/// — nothing here is invented). A single `Wrap` of fixed-minimum-width
/// tiles works for both mobile (wraps to 2 per row) and desktop (wraps to
/// however many fit the wider container) without needing two separate
/// grid implementations.
class QuickStatsGrid extends StatelessWidget {
  const QuickStatsGrid({super.key, required this.facts, this.compact = false});

  final List<QuickFact> facts;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = compact
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 12 * 2) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final fact in facts) SizedBox(width: tileWidth.clamp(140, 320), child: _QuickStatTile(fact: fact)),
          ],
        );
      },
    );
  }
}

class _QuickStatTile extends StatelessWidget {
  const _QuickStatTile({required this.fact});

  final QuickFact fact;

  @override
  Widget build(BuildContext context) {
    final profileColors = context.profileColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: profileColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: profileColors.accent.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: profileColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(fact.icon, size: 17, color: profileColors.accent),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fact.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: profileColors.textMuted, fontSize: 11),
                ),
                Text(
                  fact.value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: profileColors.text, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
