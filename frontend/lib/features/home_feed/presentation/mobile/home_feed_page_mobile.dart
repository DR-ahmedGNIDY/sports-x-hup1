import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/profile_colors.dart';
import '../shared/home_feed_body.dart';

class HomeFeedPageMobile extends StatelessWidget {
  const HomeFeedPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.profileColors.bg,
      child: const HomeFeedBody(
        maxWidth: double.infinity,
        // Full-bleed column: the cards carry small, even side gutters
        // instead of being centered inside a narrower one.
        listPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
