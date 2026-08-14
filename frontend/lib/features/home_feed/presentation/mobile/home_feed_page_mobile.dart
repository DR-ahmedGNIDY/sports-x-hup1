import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../shared/home_feed_body.dart';

class HomeFeedPageMobile extends StatelessWidget {
  const HomeFeedPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.profileBg,
      child: HomeFeedBody(maxWidth: double.infinity),
    );
  }
}
