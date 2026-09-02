import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/notifications_page_desktop.dart';
import 'mobile/notifications_page_mobile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const NotificationsPageDesktop();
  static Widget _mobile(BuildContext context) => const NotificationsPageMobile();
}
