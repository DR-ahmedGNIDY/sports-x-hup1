import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/my_traits_page_desktop.dart';
import 'mobile/my_traits_page_mobile.dart';

class MyTraitsPage extends StatelessWidget {
  const MyTraitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(desktop: _desktop, mobile: _mobile);
  }

  static Widget _desktop(BuildContext context) => const MyTraitsPageDesktop();
  static Widget _mobile(BuildContext context) => const MyTraitsPageMobile();
}
