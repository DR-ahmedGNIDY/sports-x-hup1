import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/splash_page_desktop.dart';
import 'mobile/splash_page_mobile.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Phase 0 has no auth/session check yet — just a brief branded pause
    // before landing on the empty Home shell. Phase 1 will replace this
    // with a real session check.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const SplashPageDesktop(),
      mobile: (_) => const SplashPageMobile(),
    );
  }
}
