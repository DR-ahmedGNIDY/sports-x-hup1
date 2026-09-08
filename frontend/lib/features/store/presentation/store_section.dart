import 'package:flutter/material.dart';

import '../../../core/theme/store_theme.dart';

/// Wraps a storefront page in the store's own look while it lives inside the
/// Sport X Hub app.
///
/// The two are deliberately different designs — Sport X Hub is a brand-blue
/// product app, the store is near-monochrome so the garment photography
/// carries the colour (see [StoreTheme]). Applying the theme here rather
/// than at the app root means only the store's routes change appearance,
/// and the rest of the app is untouched.
///
/// Brightness follows whatever the app is already in, so switching the app
/// to dark does not leave the store stranded in light.
class StoreSection extends StatelessWidget {
  const StoreSection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: isDark ? StoreTheme.dark : StoreTheme.light,
      child: child,
    );
  }
}
