import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/community_page_desktop.dart';
import 'mobile/community_page_mobile.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const CommunityPageDesktop();
  static Widget _mobile(BuildContext context) => const CommunityPageMobile();
}
