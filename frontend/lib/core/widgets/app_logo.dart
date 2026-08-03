import 'package:flutter/material.dart';

/// Renders the official Sport X Hub logo asset. Do not recreate the mark
/// with text/icons elsewhere — always use this widget so the branding stays
/// centralized to a single asset.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 40});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
