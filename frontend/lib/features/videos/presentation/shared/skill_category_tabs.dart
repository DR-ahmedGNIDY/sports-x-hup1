import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/skill_category.dart';

/// Horizontal chip row: the synthetic "All" tab is always prepended
/// locally (never sent to/from the server) ahead of the server-provided
/// [categories]. Selecting "All" reports [kAllSkillCategoryId] to
/// [onSelected] — callers treat that as "no category filter".
class SkillCategoryTabs extends StatelessWidget {
  const SkillCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<SkillCategory> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.profileColors;
    final tabs = [kAllSkillCategory, ...categories];
    return Container(
      // The whole row sits in one rounded panel, so the chips read as a
      // single control rather than as items floating on the page. The panel
      // is the darker `bg` while the chips are `surface`, which is what
      // makes them look contained rather than merely overlapping — on one
      // shared colour the boundary would only exist in the border.
      // Only vertical padding here. The horizontal inset is the list's own
      // (below) so that a chip scrolling out passes *through* the padded
      // area and fades at the panel edge, instead of stopping short of it
      // with a gap — padding on this Container would clip the row early and
      // make the panel look like it had simply run out of room.
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.borderOnSurface.withValues(alpha: 0.08),
        ),
      ),
      // Clipped so a chip scrolling out slides under the rounded corner
      // instead of past it — without this the row visibly overflows the
      // panel it is supposed to be inside.
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 40,
        child: ShaderMask(
          // A hard cut at the edge reads as a rendering fault; a short fade
          // reads as "there is more this way". Applied to both edges so the
          // hint is symmetric under RTL, where the row starts on the right.
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.04, 0.96, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tab = tabs[index];
              final selected = tab.id == selectedId;
              return ChoiceChip(
                label: Text(
                  (tab.id == kAllSkillCategoryId
                          ? l10n.allCategoryLabel
                          : tab.name)
                      .toUpperCase(),
                ),
                selected: selected,
                onSelected: (_) => onSelected(tab.id),
                backgroundColor: colors.surface,
                selectedColor: AppColors.profileSecondary,
                labelStyle: AppTextStyles.eyebrow.copyWith(
                  color: selected ? AppColors.white : colors.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: colors.borderOnSurface.withValues(alpha: 0.08),
                ),
                shape: const StadiumBorder(),
              );
            },
          ),
        ),
      ),
    );
  }
}
