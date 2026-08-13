import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Full-bleed, subtle brand-colored gradient band used behind the title
/// area of content-dense marketing pages (About/Pricing/Contact) that don't
/// have a natural spot for the auth flow's video-panel treatment. Borrows
/// the same "real atmosphere instead of a flat background" idea in a
/// lighter form that won't fight dense body copy.
///
/// Fades to fully transparent at the bottom so it reads as a soft header
/// wash, not a hard block, and works over both the light and dark Scaffold
/// background.
class MarketingHeaderBand extends StatelessWidget {
  const MarketingHeaderBand({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark
                ? AppColors.brandBlueDark.withValues(alpha: 0.35)
                : AppColors.brandBlueLight.withValues(alpha: 0.16),
            Colors.transparent,
          ],
        ),
      ),
      child: child,
    );
  }
}
