import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/settings_page_desktop.dart';
import 'mobile/settings_page_mobile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const SettingsPageDesktop(),
      mobile: (_) => const SettingsPageMobile(),
    );
  }
}
