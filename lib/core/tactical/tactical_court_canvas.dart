import 'dart:math' show min, max, pi;

import 'package:flutter/material.dart';

import 'court_geometry.dart';
import 'tactical_animation_engine.dart';
import 'tactical_entities.dart';
import '../models/tactical/tactical_schema.dart';

/// Full NBA basketball court in landscape.
/// Source of truth: 94 ft × 50 ft (length along X, width along Y).
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
        final idealH = w * NbaCourt.ftWidth / NbaCourt.ftLength;
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

/// NBA regulation dimensions in feet (do not mix with FIBA).
abstract final class NbaCourt {
  static const double ftLength = 94;
  static const double ftWidth = 50;
  static const double centerCircleR = 6;
  static const double keyWidth = 16;
  static const double keyDepth = 19;
  static const double freeThrowCircleR = 6;
  static const double restrictedR = 4;
  static const double threePointR = 23.75;
  static const double threePointCorner = 22;
  static const double threePointCornerRun = 14;
  static const double backboardFromBaseline = 4;
  static const double backboardWidth = 6;
  static const double rimFromBaseline = 5.25;
  static const double rimR = 0.75; // ~9 inches
  static const double laneHashStart = 7;
  static const double laneHashSpacing = 3;
  static const double laneHashLength = 0.8;
  static const double sidelineHashLength = 1.0;
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

  Offset _ft(double xFt, double yFt, double sx, double sy) => Offset(xFt * sx, yFt * sy);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sx = w / NbaCourt.ftLength;
    final sy = h / NbaCourt.ftWidth;

    // Wood floor
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFD4A574));
    final plankPaint = Paint()
      ..color = const Color(0xFFC99860).withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var y = 0.0; y < h; y += h / 18) {
      canvas.drawLine(Offset(0, y), Offset(w, y), plankPaint);
    }

    final stroke = max(1.8, w * 0.0028);
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;
    final thick = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.2, stroke * 1.25)
      ..isAntiAlias = true;

    final midX = NbaCourt.ftLength / 2;
    final midY = NbaCourt.ftWidth / 2;
    final keyHalf = NbaCourt.keyWidth / 2;

    // Paint fills (subtle contrast)
    final paintFill = Paint()..color = const Color(0xFF8B4513).withValues(alpha: 0.38);
    final centerFill = Paint()..color = const Color(0xFFA06B3C).withValues(alpha: 0.55);

    // Left key
    canvas.drawRect(
      Rect.fromLTRB(0, (midY - keyHalf) * sy, NbaCourt.keyDepth * sx, (midY + keyHalf) * sy),
      paintFill,
    );
    // Right key
    canvas.drawRect(
      Rect.fromLTRB(
        (NbaCourt.ftLength - NbaCourt.keyDepth) * sx,
        (midY - keyHalf) * sy,
        NbaCourt.ftLength * sx,
        (midY + keyHalf) * sy,
      ),
      paintFill,
    );
    // Center circle fill
    canvas.drawCircle(_ft(midX, midY, sx, sy), NbaCourt.centerCircleR * min(sx, sy), centerFill);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), thick);

    // Center line
    canvas.drawLine(_ft(midX, 0, sx, sy), _ft(midX, NbaCourt.ftWidth, sx, sy), thick);

    // Center circle
    canvas.drawCircle(_ft(midX, midY, sx, sy), NbaCourt.centerCircleR * min(sx, sy), line);

    // Half-court sideline hash marks
    final hashLen = NbaCourt.sidelineHashLength;
    canvas.drawLine(_ft(midX - hashLen / 2, 0, sx, sy), _ft(midX + hashLen / 2, 0, sx, sy), line);
    canvas.drawLine(
      _ft(midX - hashLen / 2, NbaCourt.ftWidth, sx, sy),
      _ft(midX + hashLen / 2, NbaCourt.ftWidth, sx, sy),
      line,
    );

    _drawHalf(
      canvas,
      sx: sx,
      sy: sy,
      leftBaseline: true,
      line: line,
      thick: thick,
    );
    _drawHalf(
      canvas,
      sx: sx,
      sy: sy,
      leftBaseline: false,
      line: line,
      thick: thick,
    );

    _drawLabelBox(canvas, w * 0.02, h * 0.02, 'DEFENSE', Colors.black87, Colors.white);
    _drawLabelBox(canvas, w * 0.78, h * 0.02, 'OFFENSE', const Color(0xFF3D405B), Colors.white);

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

  void _drawHalf(
    Canvas canvas, {
    required double sx,
    required double sy,
    required bool leftBaseline,
    required Paint line,
    required Paint thick,
  }) {
    final midY = NbaCourt.ftWidth / 2;
    final keyHalf = NbaCourt.keyWidth / 2;
    final scale = min(sx, sy);

    final baseline = leftBaseline ? 0.0 : NbaCourt.ftLength;
    final dir = leftBaseline ? 1.0 : -1.0; // toward midcourt
    final rimX = baseline + dir * NbaCourt.rimFromBaseline;
    final boardX = baseline + dir * NbaCourt.backboardFromBaseline;
    final ftLineX = baseline + dir * NbaCourt.keyDepth;
    final keyY0 = midY - keyHalf;
    final keyY1 = midY + keyHalf;

    // Key outline
    final keyRect = leftBaseline
        ? Rect.fromLTRB(0, keyY0 * sy, NbaCourt.keyDepth * sx, keyY1 * sy)
        : Rect.fromLTRB(
            (NbaCourt.ftLength - NbaCourt.keyDepth) * sx,
            keyY0 * sy,
            NbaCourt.ftLength * sx,
            keyY1 * sy,
          );
    canvas.drawRect(keyRect, line);

    // Free-throw circle: solid toward basket, dashed toward midcourt
    final ftCenter = _ft(ftLineX, midY, sx, sy);
    final ftR = NbaCourt.freeThrowCircleR * scale;
    // Toward basket = left half for left basket, right half for right basket
    canvas.drawArc(
      Rect.fromCircle(center: ftCenter, radius: ftR),
      leftBaseline ? pi / 2 : -pi / 2,
      pi,
      false,
      line,
    );
    _drawDashedArc(
      canvas,
      center: ftCenter,
      radius: ftR,
      startAngle: leftBaseline ? -pi / 2 : pi / 2,
      sweepAngle: pi,
      paint: line,
    );

    // Backboard (6 ft wide, centered)
    final boardHalf = NbaCourt.backboardWidth / 2;
    canvas.drawLine(
      _ft(boardX, midY - boardHalf, sx, sy),
      _ft(boardX, midY + boardHalf, sx, sy),
      thick,
    );

    // Rim
    final rim = _ft(rimX, midY, sx, sy);
    canvas.drawCircle(rim, NbaCourt.rimR * scale, Paint()..color = Colors.orange.shade800);
    canvas.drawCircle(
      rim,
      NbaCourt.rimR * scale,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = line.strokeWidth,
    );

    // Restricted area arc (4 ft from rim), facing midcourt
    canvas.drawArc(
      Rect.fromCircle(center: rim, radius: NbaCourt.restrictedR * scale),
      leftBaseline ? -pi / 2 : pi / 2,
      pi,
      false,
      line,
    );

    // Three-point corner straights (22 ft from centerline, 14 ft from baseline)
    final cornerY0 = midY - NbaCourt.threePointCorner;
    final cornerY1 = midY + NbaCourt.threePointCorner;
    final cornerEndX = baseline + dir * NbaCourt.threePointCornerRun;
    canvas.drawLine(_ft(baseline, cornerY0, sx, sy), _ft(cornerEndX, cornerY0, sx, sy), line);
    canvas.drawLine(_ft(baseline, cornerY1, sx, sy), _ft(cornerEndX, cornerY1, sx, sy), line);

    // Three-point arc (23.75 ft from rim) connecting corner lines
    final threeR = NbaCourt.threePointR * scale;
    final topCorner = _ft(cornerEndX, cornerY0, sx, sy);
    final bottomCorner = _ft(cornerEndX, cornerY1, sx, sy);
    final a0 = (topCorner - rim).direction;
    final a1 = (bottomCorner - rim).direction;
    var sweep = a1 - a0;
    // Open toward midcourt (short arc through the floor).
    if (leftBaseline) {
      while (sweep < 0) {
        sweep += 2 * pi;
      }
      while (sweep > pi) {
        sweep -= 2 * pi;
      }
    } else {
      while (sweep > 0) {
        sweep -= 2 * pi;
      }
      while (sweep < -pi) {
        sweep += 2 * pi;
      }
    }
    canvas.drawArc(Rect.fromCircle(center: rim, radius: threeR), a0, sweep, false, line);

    // Lane hash marks along key long edges, 3 ft apart from 7 ft
    final tick = NbaCourt.laneHashLength;
    for (var d = NbaCourt.laneHashStart; d < NbaCourt.keyDepth - 0.5; d += NbaCourt.laneHashSpacing) {
      final x = baseline + dir * d;
      // Outer ticks (away from lane center)
      canvas.drawLine(_ft(x, keyY0, sx, sy), _ft(x, keyY0 - tick, sx, sy), line);
      canvas.drawLine(_ft(x, keyY1, sx, sy), _ft(x, keyY1 + tick, sx, sy), line);
    }
  }

  void _drawDashedArc(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required Paint paint,
  }) {
    const dashRad = 0.12;
    const gapRad = 0.08;
    var a = startAngle;
    final end = startAngle + sweepAngle;
    final step = sweepAngle >= 0 ? 1.0 : -1.0;
    while ((step > 0 && a < end) || (step < 0 && a > end)) {
      final next = a + step * dashRad;
      final clampNext = step > 0 ? min(next, end) : max(next, end);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), a, clampNext - a, false, paint);
      a = clampNext + step * gapRad;
    }
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
