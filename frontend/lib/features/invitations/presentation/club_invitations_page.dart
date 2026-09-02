import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/club_invitations_page_desktop.dart';
import 'mobile/club_invitations_page_mobile.dart';

class ClubInvitationsPage extends StatelessWidget {
  const ClubInvitationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const ClubInvitationsPageDesktop();
  static Widget _mobile(BuildContext context) => const ClubInvitationsPageMobile();
}
