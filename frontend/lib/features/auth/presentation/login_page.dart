import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/login_page_desktop.dart';
import 'mobile/login_page_mobile.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const LoginPageDesktop(),
      mobile: (_) => const LoginPageMobile(),
    );
  }
}
