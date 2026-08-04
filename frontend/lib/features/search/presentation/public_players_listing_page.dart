import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/public_players_listing_page_desktop.dart';
import 'mobile/public_players_listing_page_mobile.dart';

class PublicPlayersListingPage extends StatelessWidget {
  const PublicPlayersListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const PublicPlayersListingPageDesktop(),
      mobile: (_) => const PublicPlayersListingPageMobile(),
    );
  }
}
