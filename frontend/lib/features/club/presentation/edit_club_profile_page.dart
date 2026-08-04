import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/edit_club_profile_page_desktop.dart';
import 'mobile/edit_club_profile_page_mobile.dart';

class EditClubProfilePage extends StatelessWidget {
  const EditClubProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const EditClubProfilePageDesktop();
  static Widget _mobile(BuildContext context) => const EditClubProfilePageMobile();
}
