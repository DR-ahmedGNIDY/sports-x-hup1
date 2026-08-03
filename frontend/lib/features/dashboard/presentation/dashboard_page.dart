import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/dashboard_page_desktop.dart';
import 'mobile/dashboard_page_mobile.dart';

/// A single logical screen for both roles' (empty, Phase 1) dashboards —
/// the roadmap lists "Empty Player Dashboard" and "Empty Club Dashboard"
/// as separate screens, but since they render identical placeholder
/// content today (routed by role, not by code), a role-parameterized page
/// is used instead of two copy-pasted files. Phase 2+ can split them into
/// genuinely different features once Player/Club dashboards grow real,
/// different content.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => const DashboardPageDesktop(),
      mobile: (_) => const DashboardPageMobile(),
    );
  }
}
