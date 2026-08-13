import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/video_repository_impl.dart';
import '../domain/entities/skill_category.dart';

/// Server-provided categories for a given sport (excludes the synthetic
/// "All" tab, which [SkillCategoryTabs] prepends locally). Keyed by sport
/// name so switching sport/tabs never mixes up category lists.
final skillCategoriesProvider = FutureProvider.family<List<SkillCategory>, String>(
  (ref, sport) => ref.watch(videoRepositoryProvider).getSkillCategories(sport),
);
