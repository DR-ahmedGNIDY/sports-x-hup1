import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/home_feed_page_desktop.dart';
import 'mobile/home_feed_page_mobile.dart';

class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const HomeFeedPageDesktop();
  static Widget _mobile(BuildContext context) => const HomeFeedPageMobile();
}
