import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/invitations_page_desktop.dart';
import 'mobile/invitations_page_mobile.dart';
import 'shared/invitations_screen_config.dart';

/// `/club/invitations` — the Club's end of the conversation.
class ClubInvitationsPage extends StatelessWidget {
  const ClubInvitationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) =>
      InvitationsPageDesktop(config: InvitationsScreenConfig.club);
  static Widget _mobile(BuildContext context) =>
      InvitationsPageMobile(config: InvitationsScreenConfig.club);
}
