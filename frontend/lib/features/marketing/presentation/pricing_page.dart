import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/pricing_page_desktop.dart';
import 'mobile/pricing_page_mobile.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const PricingPageDesktop(),
      mobile: (_) => const PricingPageMobile(),
    );
  }
}
