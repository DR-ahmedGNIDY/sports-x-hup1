import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/invitations_page_desktop.dart';
import 'mobile/invitations_page_mobile.dart';
import 'shared/invitations_screen_config.dart';

/// `/player/invitations` — the same screen as the Club's, seen from the
/// other end. Received holds clubs that invited this player; Sent holds the
/// clubs they asked to join.
class PlayerInvitationsPage extends StatelessWidget {
  const PlayerInvitationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) =>
      InvitationsPageDesktop(config: InvitationsScreenConfig.player);
  static Widget _mobile(BuildContext context) =>
      InvitationsPageMobile(config: InvitationsScreenConfig.player);
}
