import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The welcome banner at the top of Home: the brand photograph with the
/// signed-in club's (or player's) name over it, and the brand motto on the
/// far side when there is room for it.
///
/// The photograph is dark in both themes, so the text on it is always white.
class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key, required this.name});

  /// The registered club or player name. Blank while the profile loads or
  /// when none has been entered — the greeting then stands on its own.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = name?.trim() ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            height: wide ? 220 : 176,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/home_banner.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(-0.15, -0.3),
                  excludeFromSemantics: true,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [
                        AppColors.black.withValues(alpha: 0.88),
                        AppColors.black.withValues(alpha: 0.35),
                        AppColors.black.withValues(alpha: 0.15),
                        AppColors.black.withValues(alpha: wide ? 0.75 : 0.3),
                      ],
                      stops: const [0, 0.42, 0.6, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 36 : 20,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dashboardWelcomeMessageNoName,
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.8),
                                fontSize: wide ? 17 : 14,
                              ),
                            ),
                            if (displayName.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: wide ? 38 : 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              l10n.brandTagline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.85),
                                fontSize: wide ? 18 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (wide) ...[
                        const SizedBox(width: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.brandMotto,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: 44,
                                height: 2,
                                color: AppColors.white,
                              ),
                              const SizedBox(height: 14),
                              // The English motto is part of the brand
                              // artwork and stays English in both locales.
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  'STRONGER\nTOGETHER',
                                  style: TextStyle(
                                    color: AppColors.white.withValues(
                                      alpha: 0.75,
                                    ),
                                    fontSize: 10,
                                    letterSpacing: 3.2,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
