import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/public_clubs_listing_page_desktop.dart';
import 'mobile/public_clubs_listing_page_mobile.dart';

class PublicClubsListingPage extends StatelessWidget {
  const PublicClubsListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const PublicClubsListingPageDesktop(),
      mobile: (_) => const PublicClubsListingPageMobile(),
    );
  }
}
