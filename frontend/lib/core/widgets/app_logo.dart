import 'package:flutter/material.dart';

/// Renders the official SXH wordmark. Do not recreate the mark with
/// text/icons elsewhere — always use this widget so the branding stays
/// centralized to a single asset.
///
/// The mark is monochrome and ships in two inks: black for light surfaces,
/// white for dark ones. By default the ink follows the theme; pass
/// [onDark] when the logo sits on a surface whose darkness doesn't follow
/// the theme — the desktop sidebar is black in both modes.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 40, this.onDark});

  final double height;
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final dark = onDark ?? Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? 'assets/images/logo_white.png' : 'assets/images/logo_black.png',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'SXH',
    );
  }
}

/// The X mark on its own, for spaces too small for the wordmark. Same ink
/// rules as [AppLogo].
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 32, this.onDark});

  final double size;
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final dark = onDark ?? Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? 'assets/images/mark_white.png' : 'assets/images/mark_black.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
      semanticLabel: 'SXH',
    );
  }
}
