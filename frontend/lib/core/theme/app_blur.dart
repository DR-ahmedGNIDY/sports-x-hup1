import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Backdrop-blur values for the app's translucent surfaces.
///
/// A blurred bar is not decoration: it is what tells you content is still
/// there, moving underneath, rather than ending at a hard opaque edge. That
/// only works if the surface is genuinely translucent — a blur behind an
/// opaque color blurs nothing and costs a render layer for it, which is why
/// [surfaceOpacity] travels with the sigma here instead of being picked
/// separately at each call site.
abstract final class AppBlur {
  /// Sigma for a persistent bar (top app bar, bottom tab bar). Strong enough
  /// that text scrolling underneath is unreadable — a bar you can almost read
  /// through is worse than either extreme.
  static const double bar = 24;

  /// Sigma for a modal surface (sheets, overlays) that dims a larger area.
  static const double overlay = 32;

  /// How opaque a blurred surface's fill should be. Below roughly 0.6 the
  /// content underneath starts competing with the bar's own text; above 0.85
  /// the blur stops being visible at all and the layer is wasted.
  static const double surfaceOpacity = 0.72;

  /// The filter for a given sigma. Both axes always match — an asymmetric
  /// blur reads as motion, not as depth.
  static ui.ImageFilter filter(double sigma) =>
      ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
}

/// Wraps [child] in a translucent, backdrop-blurred surface of [color].
///
/// Falls back to an opaque surface when the platform asks for reduced
/// transparency — an accessibility setting that exists precisely because
/// translucent chrome is hard to read for some people, and one Flutter
/// surfaces but nothing in this app was honouring.
class BlurredSurface extends StatelessWidget {
  const BlurredSurface({
    super.key,
    required this.color,
    required this.child,
    this.sigma = AppBlur.bar,
  });

  final Color color;
  final double sigma;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceTransparency =
        MediaQuery.maybeOf(context)?.highContrast ?? false;
    if (reduceTransparency) {
      return ColoredBox(color: color, child: child);
    }

    return ClipRect(
      child: BackdropFilter(
        filter: AppBlur.filter(sigma),
        child: ColoredBox(
          color: color.withValues(alpha: AppBlur.surfaceOpacity),
          child: child,
        ),
      ),
    );
  }
}
