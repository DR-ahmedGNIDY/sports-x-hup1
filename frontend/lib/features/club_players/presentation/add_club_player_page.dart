import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/add_club_player_page_desktop.dart';
import 'mobile/add_club_player_page_mobile.dart';

class AddClubPlayerPage extends StatelessWidget {
  const AddClubPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const AddClubPlayerPageDesktop();
  static Widget _mobile(BuildContext context) => const AddClubPlayerPageMobile();
}
