import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/public_player_profile_page_desktop.dart';
import 'mobile/public_player_profile_page_mobile.dart';

class PublicPlayerProfilePage extends StatelessWidget {
  const PublicPlayerProfilePage({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (context) => PublicPlayerProfilePageDesktop(playerId: playerId),
      mobile: (context) => PublicPlayerProfilePageMobile(playerId: playerId),
    );
  }
}
