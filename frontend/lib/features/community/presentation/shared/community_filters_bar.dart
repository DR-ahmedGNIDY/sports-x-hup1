import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../player/application/lookup_providers.dart';
import '../../../player/domain/entities/lookup_option.dart';
import '../../../videos/application/skill_categories_provider.dart';
import '../../../videos/domain/entities/skill_category.dart';
import '../../../videos/presentation/shared/skill_category_tabs.dart';
import '../../application/community_feed_controller.dart';

/// Fixed display order for the sports most players care about on
/// Community; any sport not listed here (e.g. Gymnastics, Swimming) keeps
/// appearing afterward, in whatever order the API returned it.
const _pinnedSportOrder = ['Football', 'Basketball', 'Handball', 'Volleyball'];

List<LookupOption> _orderedForCommunity(List<LookupOption> sports) {
  final pinned = [
    for (final name in _pinnedSportOrder)
      ...sports.where((s) => s.name == name),
  ];
  final rest = sports.where((s) => !_pinnedSportOrder.contains(s.name));
  return [...pinned, ...rest];
}

/// Sport selector (chips, from [sportsProvider] — now naturally just the 6
/// sports) plus a category selector ([skillCategoriesProvider] + the
/// synthetic "All" tab).
class CommunityFiltersBar extends ConsumerWidget {
  const CommunityFiltersBar({super.key, required this.sport, required this.category});

  final String sport;
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportsAsync = ref.watch(sportsProvider);
    final controller = ref.read(communityFeedControllerProvider.notifier);
    final categoriesAsync = ref.watch(skillCategoriesProvider(sport));
    final colors = context.profileColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sportsAsync.when(
          data: (sports) {
            final ordered = _orderedForCommunity(sports);
            return SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ordered.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = ordered[index];
                  final selected = option.name == sport;
                  return ChoiceChip(
                    label: Text(option.name),
                    selected: selected,
                    onSelected: (_) => controller.updateSport(option.name),
                    backgroundColor: colors.surface,
                    selectedColor: AppColors.brandBlue,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.white : colors.textMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(color: colors.borderOnSurface.withValues(alpha: 0.08)),
                    shape: const StadiumBorder(),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(height: 40, child: LinearProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          data: (categories) => SkillCategoryTabs(
            categories: categories,
            selectedId: category,
            onSelected: (id) => controller.updateCategory(
              id == kAllSkillCategoryId ? null : id,
            ),
          ),
          loading: () => const SizedBox(height: 40, child: LinearProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
