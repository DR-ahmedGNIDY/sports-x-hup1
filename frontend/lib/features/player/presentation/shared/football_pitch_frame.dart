import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// The dark "SaaS scouting platform" card that houses the pitch: a near-
/// black gradient with two soft stadium-floodlight glows in the top
/// corners. Shared decorative shell — desktop and mobile presentations
/// use it identically and differ only in what they lay out inside.
class FootballPitchFrame extends StatelessWidget {
  const FootballPitchFrame({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E17), Color(0xFF060810)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              left: -40,
              child: _Glow(color: AppColors.pitchPrimary.withValues(alpha: 0.18)),
            ),
            Positioned(
              top: -60,
              right: -40,
              child: _Glow(color: AppColors.pitchPrimary.withValues(alpha: 0.18)),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class FootballPitchHeader extends StatelessWidget {
  const FootballPitchHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 34, color: AppColors.success),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.greyLight, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
