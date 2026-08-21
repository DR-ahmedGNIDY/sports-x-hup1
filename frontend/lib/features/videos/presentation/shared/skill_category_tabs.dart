import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = tab.id == selectedId;
          return ChoiceChip(
            label: Text(
              (tab.id == kAllSkillCategoryId ? l10n.allCategoryLabel : tab.name)
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
            side: BorderSide(color: colors.borderOnSurface.withValues(alpha: 0.08)),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}
