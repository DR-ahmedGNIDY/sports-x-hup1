import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/my_club_profile_page_desktop.dart';
import 'mobile/my_club_profile_page_mobile.dart';

class MyClubProfilePage extends StatelessWidget {
  const MyClubProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const MyClubProfilePageDesktop();
  static Widget _mobile(BuildContext context) => const MyClubProfilePageMobile();
}
