/// A single entry from `GET /sports/categories?sport=`. Sport is not kept
/// client-side once fetched — categories are always looked up per-sport.
class SkillCategory {
  const SkillCategory({required this.id, required this.name});

  final String id;
  final String name;
}

/// Client-only synthetic id for the "All" tab — always prepended locally,
/// never sent to or received from the backend. Selecting it means "no
/// category filter".
const String kAllSkillCategoryId = '__all__';

const SkillCategory kAllSkillCategory = SkillCategory(id: kAllSkillCategoryId, name: 'All');
