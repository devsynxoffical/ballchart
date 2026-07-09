import 'dart:math' show min, max, pi;

import 'package:flutter/material.dart';

import 'court_geometry.dart';
import 'tactical_animation_engine.dart';
import 'tactical_entities.dart';
import '../models/tactical/tactical_schema.dart';

/// Regulation-style **full basketball court** in landscape.
/// Aspect ratio is 94 ft length × 50 ft width.
class TacticalCourtCanvas extends StatelessWidget {
  final TacticalFrame frame;
  final int ballOwnerSlot;
  final double? maxHeight;
  final PlayStep? currentStep;
  final double animationProgress;

  const TacticalCourtCanvas({
    super.key,
    required this.frame,
    required this.ballOwnerSlot,
    this.maxHeight,
    this.currentStep,
    this.animationProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final idealH = w * 50 / 94;
        final h = maxHeight != null ? min(idealH, maxHeight!) : idealH;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD4A574),
              border: Border.all(color: const Color(0xFF3D405B), width: 4),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: CustomPaint(
              size: Size(w, h),
              painter: _BasketballCourtPainter(
                frame: frame,
                ballOffenseSlot: ballOwnerSlot,
                currentStep: currentStep,
                progress: animationProgress,
              ),
              child: SizedBox(width: w, height: h),
            ),
          ),
        );
      },
    );
  }
}

class _BasketballCourtPainter extends CustomPainter {
  _BasketballCourtPainter({
    required this.frame,
    required this.ballOffenseSlot,
    this.currentStep,
    this.progress = 0.0,
  });

  final TacticalFrame frame;
  final int ballOffenseSlot;
  final PlayStep? currentStep;
  final double progress;

  Offset _px(Offset norm, double w, double h) => CourtSlots.normToPixel(norm, Size(w, h));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFD4A574));

    // Subtle wood planks
    final plankPaint = Paint()
      ..color = const Color(0xFFC99860).withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var y = 0.0; y < h; y += h / 18) {
      canvas.drawLine(Offset(0, y), Offset(w, y), plankPaint);
    }

    final linePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, w * 0.004);

    final thickLine = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, w * 0.006);

    canvas.drawRect(Offset.zero & size, thickLine);

    final midY = h * 0.5;
    canvas.drawLine(Offset(0, midY), Offset(w, midY), thickLine);
    canvas.drawCircle(Offset(w / 2, midY), w * 0.12, linePaint);
    canvas.drawCircle(Offset(w / 2, midY), w * 0.04, linePaint);

    void drawEnd({required bool north}) {
      final keyDepth = h * (19 / 94);
      final keyWidth = w * (16 / 50);
      final left = (w - keyWidth) / 2;
      final top = north ? 0.0 : h - keyDepth;

      canvas.drawRect(
        Rect.fromLTWH(left, top, keyWidth, keyDepth),
        Paint()..color = const Color(0xFFB85C38).withValues(alpha: 0.45),
      );
      canvas.drawRect(Rect.fromLTWH(left, top, keyWidth, keyDepth), linePaint);

      // Free-throw circle
      final ftY = north ? top + keyDepth : top;
      canvas.drawCircle(Offset(w / 2, ftY), keyWidth / 2, linePaint);

      // Restricted area arc
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w / 2, ftY), radius: keyWidth / 2),
        north ? 0 : pi,
        pi,
        false,
        linePaint,
      );
      final rimY = north ? h * 0.052 : h - h * 0.052;
      final rimR = w * 0.018;
      final boardY = north ? 0.0 : h;
      final boardHalf = w * 0.08;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w / 2, rimY), radius: w * 0.08),
        north ? 0 : pi,
        pi,
        false,
        linePaint,
      );
      canvas.drawLine(Offset(w / 2 - boardHalf, boardY), Offset(w / 2 + boardHalf, boardY), thickLine);
      canvas.drawCircle(Offset(w / 2, rimY), rimR, Paint()..color = Colors.orange.shade800);
      canvas.drawCircle(Offset(w / 2, rimY), rimR, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);

      // Three-point arc with full corner continuity.
      final threeR = h * 0.36;
      final arcRect = Rect.fromCircle(center: Offset(w / 2, rimY), radius: threeR);
      canvas.drawArc(arcRect, north ? pi * 0.18 : pi * 1.18, pi * 0.64, false, linePaint);

      // Corner three lines
      final cornerX = w * 0.09;
      final cornerLen = h * 0.22;
      final cornerY = north ? cornerLen : h - cornerLen;
      canvas.drawLine(Offset(cornerX, rimY), Offset(cornerX, cornerY), linePaint);
      canvas.drawLine(Offset(w - cornerX, rimY), Offset(w - cornerX, cornerY), linePaint);

      // Lane hash marks (both sides) for a fuller court layout.
      final marks = [0.10, 0.16, 0.22, 0.28];
      for (final m in marks) {
        final y = north ? h * m : h - h * m;
        canvas.drawLine(Offset(left - w * 0.02, y), Offset(left, y), linePaint);
        canvas.drawLine(Offset(left + keyWidth, y), Offset(left + keyWidth + w * 0.02, y), linePaint);
      }
    }

    drawEnd(north: true);
    drawEnd(north: false);

    _drawLabelBox(canvas, w * 0.04, h * 0.02, 'DEFENSE', Colors.black87, Colors.white);
    _drawLabelBox(canvas, w * 0.04, h * 0.93, 'OFFENSE', const Color(0xFF3D405B), Colors.white);

    if (currentStep != null && progress > 0.0 && frame.startOffenseNorm != null && frame.targetOffenseNorm != null) {
      final pathPaint = Paint()
        ..color = Colors.black87.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      void drawDashedLine(Offset p1, Offset p2) {
        final dist = (p2 - p1).distance;
        if (dist < 0.1) return;
        final dir = (p2 - p1) / dist;
        const dashWidth = 8.0;
        const dashSpace = 4.0;
        var currentDistance = 0.0;
        while (currentDistance < dist) {
          final start = p1 + dir * currentDistance;
          currentDistance += dashWidth;
          if (currentDistance > dist) currentDistance = dist;
          final end = p1 + dir * currentDistance;
          canvas.drawLine(start, end, pathPaint);
          currentDistance += dashSpace;
        }
      }

      void drawArrow(Offset p1, Offset p2) {
        canvas.drawLine(p1, p2, pathPaint);
        final dist = (p2 - p1).distance;
        if (dist < 10) return;
        final dir = (p2 - p1) / dist;
        final normal = Offset(-dir.dy, dir.dx);
        const arrowSize = 10.0;
        final pt1 = p2 - dir * arrowSize + normal * (arrowSize / 2);
        final pt2 = p2 - dir * arrowSize - normal * (arrowSize / 2);
        canvas.drawLine(p2, pt1, pathPaint);
        canvas.drawLine(p2, pt2, pathPaint);
      }

      void drawScreenBar(Offset p1, Offset p2) {
        canvas.drawLine(p1, p2, pathPaint);
        final dist = (p2 - p1).distance;
        if (dist < 10) return;
        final dir = (p2 - p1) / dist;
        final normal = Offset(-dir.dy, dir.dx);
        const barSize = 16.0;
        final pt1 = p2 + normal * (barSize / 2);
        final pt2 = p2 - normal * (barSize / 2);
        canvas.drawLine(pt1, pt2, pathPaint);
      }

      Offset getPlayerPos(bool isDef, int slot, bool isStart) {
        final list = isDef
            ? (isStart ? frame.startDefenseNorm! : frame.targetDefenseNorm!)
            : (isStart ? frame.startOffenseNorm! : frame.targetOffenseNorm!);
        final idx = (slot - 1).clamp(0, 4);
        return _px(list[idx], w, h);
      }

      final step = currentStep!;
      if (step.kind == PlayStepKind.pass || step.kind == PlayStepKind.handoff) {
        if (frame.startBallNorm != null && frame.targetBallNorm != null) {
          drawDashedLine(_px(frame.startBallNorm!, w, h), _px(frame.targetBallNorm!, w, h));
        }
      } else {
        final p1 = getPlayerPos(step.isDefense, step.actorSlot, true);
        final p2 = getPlayerPos(step.isDefense, step.actorSlot, false);
        if (step.kind == PlayStepKind.screen || step.kind == PlayStepKind.staggerScreen) {
          drawScreenBar(p1, p2);
        } else if (step.kind == PlayStepKind.shoot) {
          drawDashedLine(p1, p2);
        } else {
          drawArrow(p1, p2);
        }
      }
    }

    for (var i = 0; i < frame.defenseNorm.length; i++) {
      _drawPlayer(canvas, _px(frame.defenseNorm[i], w, h), 'D${i + 1}', Colors.red.shade700, false);
    }
    for (var i = 0; i < frame.offenseNorm.length; i++) {
      final hasBall = (i + 1) == ballOffenseSlot;
      _drawPlayer(canvas, _px(frame.offenseNorm[i], w, h), 'O${i + 1}', const Color(0xFF2A4B8D), hasBall);
    }

    final bc = _px(frame.ballNorm, w, h);
    canvas.drawCircle(bc, w * 0.013, Paint()..color = Colors.orange.shade800);
    canvas.drawCircle(bc, w * 0.013, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawLabelBox(Canvas canvas, double x, double y, String text, Color bg, Color textCol) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: textCol, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromLTWH(x, y, tp.width + 12, tp.height + 6);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), Paint()..color = bg);
    tp.paint(canvas, Offset(x + 6, y + 3));
  }

  void _drawPlayer(Canvas canvas, Offset c, String label, Color color, bool highlight) {
    final r = highlight ? 14.0 : 12.0;
    canvas.drawCircle(c, r + 2, Paint()..color = Colors.black26);
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(c, r, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1.5);
    if (highlight) {
      canvas.drawCircle(c, r + 4, Paint()..color = Colors.orange.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BasketballCourtPainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.ballOffenseSlot != ballOffenseSlot ||
      oldDelegate.progress != progress ||
      oldDelegate.currentStep != currentStep;
}
