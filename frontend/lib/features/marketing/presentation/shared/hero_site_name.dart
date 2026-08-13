import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "SPORT X HUB" wordmark shown above the Home hero title. Always English
/// and always LTR — the brand name doesn't translate — styled with the
/// same blue gradient as the logo mark.
class HeroSiteName extends StatelessWidget {
  const HeroSiteName({super.key, this.fontSize = 56});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppColors.brandBlueLight, AppColors.brandBlue],
        ).createShader(bounds),
        child: Text(
          'SPORT X HUB',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            height: 1,
          ),
        ),
      ),
    );
  }
}
