import 'dart:math' show min, max;

import 'package:flutter/material.dart';

import 'tactical_animation_engine.dart';

/// Regulation-style **full court** (both ends): 5 offense (south) + 5 defense (north) + ball.
/// Aspect: NBA ~94×50 → width : height = 94 : 50.
class TacticalCourtCanvas extends StatelessWidget {
  final TacticalFrame frame;
  final int ballOwnerSlot;
  final double? maxHeight;

  const TacticalCourtCanvas({
    super.key,
    required this.frame,
    required this.ballOwnerSlot,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final idealH = w * 50 / 94;
        final h = maxHeight != null ? (idealH > maxHeight! ? maxHeight! : idealH) : idealH;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            size: Size(w, h),
            painter: _FullCourtPainter(
              frame: frame,
              ballOffenseSlot: ballOwnerSlot,
            ),
            child: SizedBox(width: w, height: h),
          ),
        );
      },
    );
  }
}

class _FullCourtPainter extends CustomPainter {
  _FullCourtPainter({
    required this.frame,
    required this.ballOffenseSlot,
  });

  final TacticalFrame frame;
  final int ballOffenseSlot;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Floor
    final floor = Paint()..color = const Color(0xFF2D4A2D);
    canvas.drawRect(Offset.zero & size, floor);

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, w * 0.002);

    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final midLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, w * 0.004);

    final circleLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, w * 0.002);

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      border,
    );

    final midY = h * 0.5;
    canvas.drawLine(Offset(0, midY), Offset(w, midY), midLine);

    final ccR = min(w, h) * 0.11;
    canvas.drawCircle(Offset(w / 2, midY), ccR, circleLine);

    void drawKey(bool top) {
      final keyW = w * 0.38;
      final keyH = h * 0.19;
      final left = (w - keyW) / 2;
      final topY = top ? h * 0.02 : h * 0.79;
      canvas.drawRect(Rect.fromLTWH(left, topY, keyW, keyH), thin);
      final hoopY = top ? topY + keyH * 0.15 : topY + keyH * 0.85;
      canvas.drawCircle(Offset(w / 2, hoopY), w * 0.012, Paint()..color = Colors.orange.shade200);
    }

    drawKey(true);
    drawKey(false);

    // 3-pt arcs (simplified elliptical arcs)
    void drawArc(bool top) {
      final cy = top ? h * 0.14 : h * 0.86;
      final arcRect = Rect.fromCenter(center: Offset(w / 2, cy), width: w * 0.92, height: h * 0.42);
      final start = top ? 0.35 * 3.14159 : 1.25 * 3.14159;
      canvas.drawArc(arcRect, start, 0.95, false, thin);
    }

    drawArc(true);
    drawArc(false);

    // Labels
    _label(canvas, w * 0.04, h * 0.04, 'DEFENSE', Colors.lightBlue.shade100);
    _label(canvas, w * 0.04, h * 0.92, 'OFFENSE', const Color(0xFFFFD900));

    // Players — defense (blue)
    for (var i = 0; i < frame.defenseNorm.length; i++) {
      final p = frame.defenseNorm[i];
      final c = Offset(p.dx * w, p.dy * h);
      _drawPlayer(canvas, c, 'D${i + 1}', const Color(0xFF4A90D9), false);
    }
    // Offense (gold / ball)
    for (var i = 0; i < frame.offenseNorm.length; i++) {
      final p = frame.offenseNorm[i];
      final c = Offset(p.dx * w, p.dy * h);
      final slot = i + 1;
      final hasBall = slot == ballOffenseSlot;
      _drawPlayer(
        canvas,
        c,
        'O$slot',
        hasBall ? const Color(0xFFFFD900) : const Color(0xFF5C4A2A),
        hasBall,
      );
    }

    // Ball (extra ring if not overlapping)
    final b = frame.ballNorm;
    final bc = Offset(b.dx * w, b.dy * h);
    canvas.drawCircle(bc, w * 0.014, Paint()..color = Colors.deepOrange.shade200);
    canvas.drawCircle(bc, w * 0.014, Paint()..color = Colors.white.withValues(alpha: 0.9)..style = PaintingStyle.stroke..strokeWidth = 1.2);
  }

  void _label(Canvas canvas, double x, double y, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  void _drawPlayer(Canvas canvas, Offset c, String label, Color fill, bool emphasize) {
    final r = emphasize ? 13.0 : 11.0;
    canvas.drawCircle(c, r, Paint()..color = fill);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: emphasize ? Colors.black : Colors.white,
          fontSize: emphasize ? 9 : 8,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FullCourtPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.ballOffenseSlot != ballOffenseSlot;
}
