import 'package:flutter/widgets.dart';

import '../utils/breakpoints.dart';

/// Mounts exactly one of two independent widget subtrees based on
/// [AppBreakpoints]. This is the single decision point every screen uses to
/// fork into its Desktop or Mobile presentation — the two builders are
/// expected to be entirely separate widget trees (different files, under
/// `presentation/desktop` and `presentation/mobile`), not a shared widget
/// with conditional styling inside it.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.desktop,
    required this.mobile,
  });

  final WidgetBuilder desktop;
  final WidgetBuilder mobile;

  @override
  Widget build(BuildContext context) {
    return AppBreakpoints.isDesktop(context)
        ? desktop(context)
        : mobile(context);
  }
}
