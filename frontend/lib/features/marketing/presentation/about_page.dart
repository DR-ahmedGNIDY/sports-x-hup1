import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/about_page_desktop.dart';
import 'mobile/about_page_mobile.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const AboutPageDesktop(),
      mobile: (_) => const AboutPageMobile(),
    );
  }
}
