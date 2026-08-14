import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The premium dark card shell used throughout the redesigned Player
/// Profile — a titled section on [AppColors.profileSurface] with a
/// subtle border and shadow. Shared by every section (About, Current
/// Club, trailing sections) on both desktop and mobile; only how these
/// cards are arranged (side-by-side vs stacked) differs per platform.
class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    this.icon,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accentColor = AppColors.profileAccent,
  });

  final IconData? icon;
  final String title;
  final Widget child;
  final EdgeInsets padding;

  /// Icon/hairline-glow tint. Defaults to the app-wide cyan/blue accent;
  /// pass [AppColors.profileGold] (achievements) or
  /// [AppColors.profileNeonGreen] (active/status highlights) to opt a
  /// specific card into the redesign's other two accent colors without
  /// duplicating this card's chrome.
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.profileSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: accentColor.withValues(alpha: 0.05), blurRadius: 24, spreadRadius: -6),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: accentColor),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: AppColors.profileText, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
