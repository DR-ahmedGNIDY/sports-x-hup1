import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/register_page_desktop.dart';
import 'mobile/register_page_mobile.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const RegisterPageDesktop(),
      mobile: (_) => const RegisterPageMobile(),
    );
  }
}
