import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Which scene [EmptyStateIllustration] paints. Pick the variant that
/// matches why the list is empty, not just where it's used:
///  - [noVideos] — nothing has been uploaded/posted yet (a genuinely empty
///    collection).
///  - [noResults] — a search/filter narrowed an otherwise non-empty
///    collection down to zero matches.
///  - [noData] — a generic "nothing here" case that isn't specifically
///    about videos or a search (e.g. an empty list/table section).
enum EmptyStateVariant { noVideos, noResults, noData }

/// A small, on-brand line-art scene for empty states, drawn with
/// [CustomPainter] (no image/SVG assets, no new dependency). Meant to sit
/// behind an existing empty-state message as a subtle backdrop — shapes are
/// stroked at low opacity using [AppColors] tokens so it reads as
/// "considered" rather than a competing focal illustration.
///
/// Usage: drop it directly above the existing empty-state text, e.g.
/// ```dart
/// Column(
///   mainAxisSize: MainAxisSize.min,
///   children: [
///     const EmptyStateIllustration(variant: EmptyStateVariant.noVideos),
///     const SizedBox(height: AppSpacing.md),
///     Text(l10n.someEmptyStateMessage),
///   ],
/// )
/// ```
class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({
    super.key,
    required this.variant,
    this.size = 140,
  });

  final EmptyStateVariant variant;

  /// Side length of the (square) painted area. Defaults to a size that
  /// reads clearly without competing with the message text below it.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmptyStatePainter(variant: variant),
      ),
    );
  }
}

class _EmptyStatePainter extends CustomPainter {
  _EmptyStatePainter({required this.variant});

  final EmptyStateVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.shortestSide;

    final outline = Paint()
      ..color = AppColors.greyLight.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * 0.02
      ..strokeCap = StrokeCap.round;

    final accent = Paint()
      ..color = AppColors.brandBlueLight.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * 0.02
      ..strokeCap = StrokeCap.round;

    switch (variant) {
      case EmptyStateVariant.noVideos:
        _paintNoVideos(canvas, center, scale, outline, accent);
      case EmptyStateVariant.noResults:
        _paintNoResults(canvas, center, scale, outline, accent);
      case EmptyStateVariant.noData:
        _paintNoData(canvas, center, scale, outline, accent);
    }
  }

  /// A rounded play button with a faint dashed outline ring behind it.
  void _paintNoVideos(
    Canvas canvas,
    Offset center,
    double scale,
    Paint outline,
    Paint accent,
  ) {
    _drawDashedCircle(canvas, center, scale * 0.34, accent);

    final buttonRadius = scale * 0.22;
    final buttonRect = Rect.fromCircle(center: center, radius: buttonRadius);
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, Radius.circular(buttonRadius)),
      outline,
    );

    final triangleSize = buttonRadius * 0.75;
    final path = Path()
      ..moveTo(center.dx - triangleSize * 0.35, center.dy - triangleSize * 0.55)
      ..lineTo(center.dx - triangleSize * 0.35, center.dy + triangleSize * 0.55)
      ..lineTo(center.dx + triangleSize * 0.55, center.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = AppColors.greyLight.withValues(alpha: 0.4),
    );
  }

  /// A magnifying glass with a faint dotted "search trail".
  void _paintNoResults(
    Canvas canvas,
    Offset center,
    double scale,
    Paint outline,
    Paint accent,
  ) {
    final glassCenter = Offset(center.dx - scale * 0.06, center.dy - scale * 0.06);
    final glassRadius = scale * 0.18;

    canvas.drawCircle(glassCenter, glassRadius, outline);

    final handleStart = Offset(
      glassCenter.dx + glassRadius * 0.75,
      glassCenter.dy + glassRadius * 0.75,
    );
    final handleEnd = Offset(center.dx + scale * 0.22, center.dy + scale * 0.22);
    canvas.drawLine(handleStart, handleEnd, outline);

    // Faint dotted trail suggesting a search that came up short.
    final dotPaint = Paint()
      ..color = AppColors.brandBlueLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final trailStart = handleEnd + const Offset(6, 6);
    for (var i = 0; i < 3; i++) {
      final t = i / 2;
      final dot = Offset(
        trailStart.dx + scale * 0.09 * t,
        trailStart.dy + scale * 0.09 * t,
      );
      canvas.drawCircle(dot, scale * 0.012, dotPaint);
    }
  }

  /// A simple stack of two rounded-rect "cards" suggesting an empty list.
  void _paintNoData(
    Canvas canvas,
    Offset center,
    double scale,
    Paint outline,
    Paint accent,
  ) {
    final backRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center + Offset(scale * 0.06, -scale * 0.06),
        width: scale * 0.5,
        height: scale * 0.34,
      ),
      Radius.circular(scale * 0.04),
    );
    canvas.drawRRect(backRect, accent);

    final frontRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center + Offset(-scale * 0.04, scale * 0.04),
        width: scale * 0.5,
        height: scale * 0.34,
      ),
      Radius.circular(scale * 0.04),
    );
    canvas.drawRRect(frontRect, outline);

    // Two short lines inside the front card, standing in for empty content.
    final lineY1 = frontRect.center.dy - scale * 0.04;
    final lineY2 = frontRect.center.dy + scale * 0.04;
    final lineLeft = frontRect.left + scale * 0.08;
    final lineRight = frontRect.right - scale * 0.08;
    canvas.drawLine(Offset(lineLeft, lineY1), Offset(lineRight, lineY1), outline);
    canvas.drawLine(
      Offset(lineLeft, lineY2),
      Offset(lineRight - scale * 0.12, lineY2),
      outline,
    );
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashCount = 24;
    const dashFraction = 0.55; // portion of each segment that's drawn.
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * 3.141592653589793;
      final sweep = (2 * 3.141592653589793 / dashCount) * dashFraction;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyStatePainter oldDelegate) =>
      oldDelegate.variant != variant;
}
