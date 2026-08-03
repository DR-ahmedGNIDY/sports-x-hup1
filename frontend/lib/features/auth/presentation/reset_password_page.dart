import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/reset_password_page_desktop.dart';
import 'mobile/reset_password_page_mobile.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key, required this.token});

  final String? token;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => ResetPasswordPageDesktop(token: token),
      mobile: (_) => ResetPasswordPageMobile(token: token),
    );
  }
}
