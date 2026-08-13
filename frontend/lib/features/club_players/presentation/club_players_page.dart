import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/club_players_page_desktop.dart';
import 'mobile/club_players_page_mobile.dart';

class ClubPlayersPage extends StatelessWidget {
  const ClubPlayersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const ClubPlayersPageDesktop();
  static Widget _mobile(BuildContext context) => const ClubPlayersPageMobile();
}
