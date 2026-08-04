import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/contact_page_desktop.dart';
import 'mobile/contact_page_mobile.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const ContactPageDesktop(),
      mobile: (_) => const ContactPageMobile(),
    );
  }
}
