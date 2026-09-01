import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../shared/my_skills_page_body.dart';

class MySkillsPageMobile extends StatelessWidget {
  const MySkillsPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffoldMobile(
      background: context.profileColors.bg,
      slivers: const [
        SliverPadding(
          padding: EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(child: MySkillsPageBody()),
        ),
      ],
    );
  }
}
