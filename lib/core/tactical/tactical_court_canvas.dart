import 'dart:math' show min, max;

import 'package:flutter/material.dart';

import 'tactical_animation_engine.dart';
import 'tactical_entities.dart';
import '../models/tactical/tactical_schema.dart';
/// Regulation-style **full court** (both ends): 5 offense (south) + 5 defense (north) + ball.
/// Aspect: NBA ~94×50 → width : height = 94 : 50.
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
        final h = maxHeight != null ? (idealH > maxHeight! ? maxHeight! : idealH) : idealH;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1DE),
              border: Border.all(color: const Color(0xFF3D405B), width: 8),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: CustomPaint(
              size: Size(w, h),
              painter: _FullCourtPainter(
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

class _FullCourtPainter extends CustomPainter {
  _FullCourtPainter({
    required this.frame,
    required this.ballOffenseSlot,
    this.currentStep,
    this.progress = 0.0,
  });

  final TacticalFrame frame;
  final int ballOffenseSlot;
  final PlayStep? currentStep;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Wood Texture (Background)
    final woodColor = const Color(0xFFF2CC8F);
    canvas.drawRect(Offset.zero & size, Paint()..color = woodColor);

    // Court lines paint
    final linePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, w * 0.003);

    final thickLine = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.5, w * 0.005);

    // Border
    canvas.drawRect(Offset.zero & size, thickLine);

    // Midcourt line
    final midX = w * 0.5;
    canvas.drawLine(Offset(midX, 0), Offset(midX, h), thickLine);
    canvas.drawCircle(Offset(midX, h / 2), w * 0.06, linePaint);

    void drawSide(bool left) {
      final keyW = w * 0.202; // 19ft on 94ft
      final keyH = h * 0.32; // 16ft on 50ft
      final startX = left ? 0.0 : w - keyW;
      final topY = (h - keyH) / 2;

      // Key (Paint area) - matching the orange in reference
      final keyColor = const Color(0xFFE07A5F);
      canvas.drawRect(Rect.fromLTWH(startX, topY, keyW, keyH), Paint()..color = keyColor);
      canvas.drawRect(Rect.fromLTWH(startX, topY, keyW, keyH), linePaint);

      // Free throw circle
      final ftR = keyH / 2;
      final ftCenterX = left ? keyW : w - keyW;
      canvas.drawCircle(Offset(ftCenterX, h / 2), ftR, linePaint);

      // Hoop and Backboard
      final rimX = left ? w * 0.056 : w - (w * 0.056);
      final bbX = left ? w * 0.043 : w - (w * 0.043);
      final bbH = h * 0.12;
      canvas.drawLine(Offset(bbX, h / 2 - bbH / 2), Offset(bbX, h / 2 + bbH / 2), thickLine);

      // Rim
      final rimR = w * 0.012;
      canvas.drawCircle(Offset(rimX, h / 2), rimR, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);

      // 3-pt arc
      final threeR = h * 0.475;
      final rect = Rect.fromCircle(center: Offset(rimX, h / 2), radius: threeR);
      final startAngle = left ? -1.57 : 1.57;
      canvas.drawArc(rect, startAngle, 3.14159, false, linePaint);
    }

    drawSide(true);
    drawSide(false);

    // Reference Labels (Attacking / Defense)
    _drawLabelBox(canvas, w * 0.15, h * 0.05, 'ATTACKING', const Color(0xFF3D405B), Colors.white);
    _drawLabelBox(canvas, w * 0.65, h * 0.05, 'DEFENSE RESPONSIBILITY', Colors.black87, Colors.white);
    
    _drawLabelBox(canvas, w * 0.15, h * 0.88, 'COACHING BOARD', Colors.black87, Colors.white, small: true);
    _drawLabelBox(canvas, w * 0.65, h * 0.88, 'FULL COURT', const Color(0xFF3D405B), Colors.white, small: true);

    // --- Paths & Indicators (drawn below players) ---
    if (currentStep != null && progress > 0.0 && frame.startOffenseNorm != null && frame.targetOffenseNorm != null) {
      final pathPaint = Paint()
        ..color = Colors.black87.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      void drawDashedLine(Offset p1, Offset p2) {
        final dist = (p2 - p1).distance;
        if (dist < 0.1) return;
        final dir = (p2 - p1) / dist;
        double dashWidth = 8.0;
        double dashSpace = 4.0;
        double currentDistance = 0.0;
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
        final p = list[idx];
        return Offset(p.dy * w, p.dx * h);
      }

      final step = currentStep!;
      if (step.kind == PlayStepKind.pass || step.kind == PlayStepKind.handoff) {
        if (frame.startBallNorm != null && frame.targetBallNorm != null) {
          final p1 = Offset(frame.startBallNorm!.dy * w, frame.startBallNorm!.dx * h);
          final p2 = Offset(frame.targetBallNorm!.dy * w, frame.targetBallNorm!.dx * h);
          drawDashedLine(p1, p2);
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

    // Players
    for (var i = 0; i < frame.defenseNorm.length; i++) {
      final p = frame.defenseNorm[i];
      // In horizontal: 0 is left, 1 is right.
      final c = Offset(p.dy * w, p.dx * h); 
      _drawPuck(canvas, c, 'D${i + 1}', Colors.red.shade700, false);
    }
    for (var i = 0; i < frame.offenseNorm.length; i++) {
      final p = frame.offenseNorm[i];
      final c = Offset(p.dy * w, p.dx * h);
      final hasBall = (i + 1) == ballOffenseSlot;
      _drawPuck(canvas, c, 'O${i + 1}', const Color(0xFFF2CC8F), hasBall);
    }
    
    // Ball
    final b = frame.ballNorm;
    final bc = Offset(b.dy * w, b.dx * h);
    canvas.drawCircle(bc, w * 0.012, Paint()..color = Colors.orange.shade800);
    canvas.drawCircle(bc, w * 0.012, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawLabelBox(Canvas canvas, double x, double y, String text, Color bg, Color textCol, {bool small = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: textCol, fontSize: small ? 8 : 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    final rect = Rect.fromLTWH(x, y, tp.width + 16, tp.height + 8);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), Paint()..color = bg);
    tp.paint(canvas, Offset(x + 8, y + 4));
  }

  void _drawPuck(Canvas canvas, Offset c, String label, Color color, bool highlight) {
    final r = highlight ? 14.0 : 12.0;
    // Outer ring
    canvas.drawCircle(c, r + 2, Paint()..color = Colors.black26);
    // Body
    canvas.drawCircle(c, r, Paint()..color = color);
    // Border
    canvas.drawCircle(c, r, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1.5);
    
    if (highlight) {
      canvas.drawCircle(c, r + 4, Paint()..color = Colors.orange.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FullCourtPainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.ballOffenseSlot != ballOffenseSlot ||
      oldDelegate.progress != progress ||
      oldDelegate.currentStep != currentStep;
}
