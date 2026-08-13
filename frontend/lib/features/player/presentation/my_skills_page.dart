import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/my_skills_page_desktop.dart';
import 'mobile/my_skills_page_mobile.dart';

class MySkillsPage extends StatelessWidget {
  const MySkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const MySkillsPageDesktop();
  static Widget _mobile(BuildContext context) => const MySkillsPageMobile();
}
