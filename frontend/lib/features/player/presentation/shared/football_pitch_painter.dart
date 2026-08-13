import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Paints a premium, top-down-with-depth football pitch: a slight
/// perspective trapezoid (narrower far touchline, wider near touchline —
/// the same convention broadcast tactical graphics use), a subtle
/// mown-grass gradient, and glowing pitch markings. Pure Flutter drawing,
/// no image asset, so it stays sharp at any size.
class FootballPitchPainter extends CustomPainter {
  const FootballPitchPainter({this.topWidthFactor = 0.58});

  /// Width of the far (top) touchline as a fraction of the near (bottom)
  /// touchline — the smaller this is, the stronger the depth illusion.
  final double topWidthFactor;

  /// Maps normalized pitch coordinates (`u` across the pitch `0..1` left
  /// to right, `v` down the pitch `0..1` far to near) to a screen offset
  /// inside [rect], applying the trapezoid perspective.
  Offset toScreen(Rect rect, double u, double v) {
    final rowWidth = lerpDouble(rect.width * topWidthFactor, rect.width, v)!;
    final rowLeft = rect.left + (rect.width - rowWidth) / 2;
    return Offset(rowLeft + u * rowWidth, rect.top + v * rect.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pitchPath = Path()
      ..moveTo(toScreen(rect, 0, 0).dx, toScreen(rect, 0, 0).dy)
      ..lineTo(toScreen(rect, 1, 0).dx, toScreen(rect, 1, 0).dy)
      ..lineTo(toScreen(rect, 1, 1).dx, toScreen(rect, 1, 1).dy)
      ..lineTo(toScreen(rect, 0, 1).dx, toScreen(rect, 0, 1).dy)
      ..close();

    canvas.save();
    canvas.clipPath(pitchPath);

    final grassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF123A24), Color(0xFF184A2E), Color(0xFF123A24)],
      ).createShader(rect);
    canvas.drawRect(rect, grassPaint);

    // Alternating mow stripes, each a horizontal band in pitch-space.
    const stripeCount = 10;
    for (var i = 0; i < stripeCount; i++) {
      if (i.isOdd) continue;
      final v0 = i / stripeCount;
      final v1 = (i + 1) / stripeCount;
      final stripe = Path()
        ..moveTo(toScreen(rect, 0, v0).dx, toScreen(rect, 0, v0).dy)
        ..lineTo(toScreen(rect, 1, v0).dx, toScreen(rect, 1, v0).dy)
        ..lineTo(toScreen(rect, 1, v1).dx, toScreen(rect, 1, v1).dy)
        ..lineTo(toScreen(rect, 0, v1).dx, toScreen(rect, 0, v1).dy)
        ..close();
      canvas.drawPath(stripe, Paint()..color = Colors.white.withValues(alpha: 0.035));
    }
    canvas.restore();

    _drawMarkings(canvas, rect);
  }

  void _drawMarkings(Canvas canvas, Rect rect) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    void drawQuad(double u0, double v0, double u1, double v1) {
      final path = Path()
        ..moveTo(toScreen(rect, u0, v0).dx, toScreen(rect, u0, v0).dy)
        ..lineTo(toScreen(rect, u1, v0).dx, toScreen(rect, u1, v0).dy)
        ..lineTo(toScreen(rect, u1, v1).dx, toScreen(rect, u1, v1).dy)
        ..lineTo(toScreen(rect, u0, v1).dx, toScreen(rect, u0, v1).dy)
        ..close();
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, linePaint);
    }

    void drawLine(double u0, double v0, double u1, double v1) {
      final p0 = toScreen(rect, u0, v0);
      final p1 = toScreen(rect, u1, v1);
      canvas.drawLine(p0, p1, glowPaint);
      canvas.drawLine(p0, p1, linePaint);
    }

    // Outer boundary.
    drawQuad(0, 0, 1, 1);
    // Halfway line.
    drawLine(0, 0.5, 1, 0.5);

    // Centre circle + spot — an ellipse in screen space approximates the
    // circle warped by the trapezoid perspective closely enough at this
    // scale, and stays cheap to draw every frame.
    final centre = toScreen(rect, 0.5, 0.5);
    final radiusX = rect.width * 0.16 * lerpDouble(topWidthFactor, 1, 0.5)!;
    final radiusY = rect.height * 0.1;
    final circleRect = Rect.fromCenter(
      center: centre,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    canvas.drawOval(circleRect, glowPaint);
    canvas.drawOval(circleRect, linePaint);
    canvas.drawCircle(centre, 2.6, Paint()..color = Colors.white.withValues(alpha: 0.85));

    // Penalty + goal areas, both ends. Far end (v near 0) is narrower on
    // screen thanks to the trapezoid, matching real broadcast graphics.
    for (final end in [0.0, 1.0]) {
      final dir = end == 0.0 ? 1 : -1;
      final penaltyDepth = 0.16 * dir;
      final goalDepth = 0.06 * dir;
      drawQuad(0.22, end, 0.78, end + penaltyDepth);
      drawQuad(0.37, end, 0.63, end + goalDepth);

      // Penalty arc.
      final spotV = end + 0.11 * dir;
      final spot = toScreen(rect, 0.5, spotV);
      canvas.drawCircle(spot, 2.4, Paint()..color = Colors.white.withValues(alpha: 0.85));
      final arcRect = Rect.fromCenter(
        center: toScreen(rect, 0.5, end + penaltyDepth),
        width: rect.width * 0.22,
        height: rect.height * 0.1,
      );
      final startAngle = end == 0.0 ? 0.0 : math.pi;
      canvas.drawArc(arcRect, startAngle, math.pi, false, glowPaint);
      canvas.drawArc(arcRect, startAngle, math.pi, false, linePaint);

      // Goal frame, drawn just outside the pitch boundary.
      final goalLeft = toScreen(rect, 0.42, end);
      final goalRight = toScreen(rect, 0.58, end);
      final outward = end == 0.0 ? -1 : 1;
      final goalDepthPx = rect.height * 0.035 * outward;
      final goalPath = Path()
        ..moveTo(goalLeft.dx, goalLeft.dy)
        ..lineTo(goalLeft.dx, goalLeft.dy + goalDepthPx)
        ..lineTo(goalRight.dx, goalRight.dy + goalDepthPx)
        ..lineTo(goalRight.dx, goalRight.dy);
      canvas.drawPath(goalPath, linePaint);
    }

    // Corner arcs.
    for (final corner in [const Offset(0, 0), const Offset(1, 0), const Offset(0, 1), const Offset(1, 1)]) {
      final centrePt = toScreen(rect, corner.dx, corner.dy);
      final cornerRect = Rect.fromCenter(center: centrePt, width: 22, height: 16);
      final angle = switch (corner) {
        Offset(dx: 0, dy: 0) => 0.0,
        Offset(dx: 1, dy: 0) => math.pi / 2,
        Offset(dx: 0, dy: 1) => -math.pi / 2,
        _ => math.pi,
      };
      canvas.drawArc(cornerRect, angle, math.pi / 2, false, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FootballPitchPainter oldDelegate) =>
      oldDelegate.topWidthFactor != topWidthFactor;
}
