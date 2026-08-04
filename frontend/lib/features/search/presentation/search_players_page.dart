import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/search_players_page_desktop.dart';
import 'mobile/search_players_page_mobile.dart';

class SearchPlayersPage extends StatelessWidget {
  const SearchPlayersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const SearchPlayersPageDesktop();
  static Widget _mobile(BuildContext context) => const SearchPlayersPageMobile();
}
