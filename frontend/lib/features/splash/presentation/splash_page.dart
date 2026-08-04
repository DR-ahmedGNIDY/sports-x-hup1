import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/splash_page_desktop.dart';
import 'mobile/splash_page_mobile.dart';

/// Purely a loading display while the session restores. The restore() call
/// itself is triggered once at app root (see SportXHubApp.initState) so it
/// also covers cold loads that land on a route Splash never mounts for
/// (e.g. a shared /players/:id link). Restoring flips SessionController's
/// status away from `unknown`, which the router's redirect (reactive via
/// GoRouterRefreshNotifier) picks up to send an unauthenticated/authenticated
/// user to /login or /dashboard — this screen never navigates itself.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const SplashPageDesktop(),
      mobile: (_) => const SplashPageMobile(),
    );
  }
}
