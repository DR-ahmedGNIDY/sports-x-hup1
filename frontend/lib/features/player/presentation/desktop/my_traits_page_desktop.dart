import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../shared/my_traits_page_body.dart';

class MyTraitsPageDesktop extends StatelessWidget {
  const MyTraitsPageDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.profileBg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: MyTraitsPageBody(),
          ),
        ),
      ),
    );
  }
}
