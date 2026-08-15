import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/profile_colors.dart';
import '../shared/my_traits_page_body.dart';

class MyTraitsPageMobile extends StatelessWidget {
  const MyTraitsPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.profileColors.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: const MyTraitsPageBody(),
      ),
    );
  }
}
