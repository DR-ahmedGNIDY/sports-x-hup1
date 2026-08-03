import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../auth/application/session_controller.dart';
import 'desktop/splash_page_desktop.dart';
import 'mobile/splash_page_mobile.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Restoring flips SessionController's status away from `unknown`, which
    // the router's redirect (reactive via GoRouterRefreshNotifier) picks up
    // to send us to /login or /dashboard — this screen never navigates
    // itself.
    Future.microtask(() => ref.read(sessionControllerProvider.notifier).restore());
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const SplashPageDesktop(),
      mobile: (_) => const SplashPageMobile(),
    );
  }
}
