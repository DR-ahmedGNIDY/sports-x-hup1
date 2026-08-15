import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/profile_colors.dart';
import '../shared/my_skills_page_body.dart';

class MySkillsPageDesktop extends StatelessWidget {
  const MySkillsPageDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.profileColors.bg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: MySkillsPageBody(),
          ),
        ),
      ),
    );
  }
}
