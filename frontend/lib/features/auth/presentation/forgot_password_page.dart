import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/forgot_password_page_desktop.dart';
import 'mobile/forgot_password_page_mobile.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const ForgotPasswordPageDesktop(),
      mobile: (_) => const ForgotPasswordPageMobile(),
    );
  }
}
