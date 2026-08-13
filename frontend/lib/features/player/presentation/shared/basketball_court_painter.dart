import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints a realistic top-down basketball half-court: hardwood boards,
/// the paint (key), free-throw line and circle, three-point arc, basket
/// and backboard at the baseline, and a center-circle stub bleeding off
/// the top edge to imply the center line without needing a full court.
/// Pure Flutter drawing, no image asset, so it stays sharp at any size.
class BasketballCourtPainter extends CustomPainter {
  const BasketballCourtPainter();

  /// Maps normalized court coordinates (`u` across the court `0..1` left
  /// to right, `v` down the court `0..1` center-line to baseline) to a
  /// screen offset inside [rect].
  Offset toScreen(Rect rect, double u, double v) => Offset(rect.left + u * rect.width, rect.top + v * rect.height);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.save();
    canvas.clipRect(rect);

    final woodPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7A4A24), Color(0xFF8F5A2E), Color(0xFF7A4A24)],
      ).createShader(rect);
    canvas.drawRect(rect, woodPaint);

    // Subtle plank striping running the length of the court.
    const plankCount = 14;
    for (var i = 0; i < plankCount; i++) {
      if (i.isOdd) continue;
      final u0 = i / plankCount;
      final u1 = (i + 1) / plankCount;
      canvas.drawRect(
        Rect.fromLTRB(
          toScreen(rect, u0, 0).dx,
          rect.top,
          toScreen(rect, u1, 0).dx,
          rect.bottom,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.04),
      );
    }
    canvas.restore();

    _drawMarkings(canvas, rect);
  }

  void _drawMarkings(Canvas canvas, Rect rect) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    void drawRectUV(double u0, double v0, double u1, double v1) {
      final r = Rect.fromPoints(toScreen(rect, u0, v0), toScreen(rect, u1, v1));
      canvas.drawRect(r, glowPaint);
      canvas.drawRect(r, linePaint);
    }

    // Outer boundary (sidelines + baseline; center line is the top edge).
    drawRectUV(0, 0, 1, 1);

    // Center circle stub — centered exactly on the top edge so only its
    // bottom half is visible, implying the center line without drawing a
    // full court.
    final centerSpot = toScreen(rect, 0.5, 0);
    final centerRadius = rect.width * 0.11;
    canvas.drawArc(
      Rect.fromCircle(center: centerSpot, radius: centerRadius),
      0,
      math.pi,
      false,
      glowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: centerSpot, radius: centerRadius),
      0,
      math.pi,
      false,
      linePaint,
    );

    // The paint (key), free-throw line at v = 0.62.
    const paintTop = 0.62;
    drawRectUV(0.34, paintTop, 0.66, 1.0);

    // Free-throw circle, centered on the free-throw line.
    final ftSpot = toScreen(rect, 0.5, paintTop);
    final ftRadius = rect.width * 0.14;
    canvas.drawOval(Rect.fromCircle(center: ftSpot, radius: ftRadius), glowPaint);
    canvas.drawOval(Rect.fromCircle(center: ftSpot, radius: ftRadius), linePaint);

    // Basket + backboard near the baseline.
    const basketV = 0.93;
    final backboardLeft = toScreen(rect, 0.42, basketV);
    final backboardRight = toScreen(rect, 0.58, basketV);
    canvas.drawLine(backboardLeft, backboardRight, linePaint);
    final rimSpot = toScreen(rect, 0.5, basketV + 0.035);
    final rimRadius = rect.width * 0.028;
    canvas.drawOval(Rect.fromCircle(center: rimSpot, radius: rimRadius), linePaint);

    // Three-point arc, centered on the basket. Solved so both endpoints
    // land exactly on the baseline — `theta` is the angle (from the
    // horizontal) at which the circle crosses the baseline, giving a
    // right-corner angle of `theta` and a left-corner angle of `pi -
    // theta`, symmetric about the top of the arc.
    final arcCenter = toScreen(rect, 0.5, basketV + 0.035);
    final arcRadius = rect.width * 0.46;
    final baselineOffset = rect.bottom - arcCenter.dy;
    final theta = math.asin((baselineOffset / arcRadius).clamp(-1.0, 1.0));
    final arcRect = Rect.fromCircle(center: arcCenter, radius: arcRadius);
    canvas.drawArc(arcRect, theta, -(math.pi + 2 * theta), false, glowPaint);
    canvas.drawArc(arcRect, theta, -(math.pi + 2 * theta), false, linePaint);
  }

  @override
  bool shouldRepaint(covariant BasketballCourtPainter oldDelegate) => false;
}
