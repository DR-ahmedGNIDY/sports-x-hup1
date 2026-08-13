import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../shared/my_traits_page_body.dart';

class MyTraitsPageMobile extends StatelessWidget {
  const MyTraitsPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.profileBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: const MyTraitsPageBody(),
      ),
    );
  }
}
