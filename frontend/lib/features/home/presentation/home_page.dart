import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/home_page_desktop.dart';
import 'mobile/home_page_mobile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const HomePageDesktop(),
      mobile: (_) => const HomePageMobile(),
    );
  }
}
