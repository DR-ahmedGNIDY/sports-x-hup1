import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/saved_players_page_desktop.dart';
import 'mobile/saved_players_page_mobile.dart';

class SavedPlayersPage extends StatelessWidget {
  const SavedPlayersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const SavedPlayersPageDesktop();
  static Widget _mobile(BuildContext context) => const SavedPlayersPageMobile();
}
