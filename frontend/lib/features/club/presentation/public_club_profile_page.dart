import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/public_club_profile_page_desktop.dart';
import 'mobile/public_club_profile_page_mobile.dart';

class PublicClubProfilePage extends StatelessWidget {
  const PublicClubProfilePage({super.key, required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (context) => PublicClubProfilePageDesktop(clubId: clubId),
      mobile: (context) => PublicClubProfilePageMobile(clubId: clubId),
    );
  }
}
