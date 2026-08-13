import '../../videos/domain/entities/skill_category.dart';

class CommunityFilters {
  const CommunityFilters({required this.sport, this.category, this.page = 1});

  final String sport;
  final String? category;
  final int page;

  CommunityFilters copyWith({String? sport, String? category, bool clearCategory = false, int? page}) {
    return CommunityFilters(
      sport: sport ?? this.sport,
      category: clearCategory ? null : (category ?? this.category),
      page: page ?? this.page,
    );
  }
}

/// Normalizes the synthetic "All" tab id to `null` for the wire filter.
String? communityCategoryFilter(String? category) =>
    category == kAllSkillCategoryId ? null : category;
