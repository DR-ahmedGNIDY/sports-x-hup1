import '../../domain/entities/skill_category.dart';

extension SkillCategoryModel on SkillCategory {
  static SkillCategory fromJson(Map<String, dynamic> json) {
    return SkillCategory(id: json['id'] as String, name: json['name'] as String);
  }
}
