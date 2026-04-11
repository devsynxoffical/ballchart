import 'package:flutter/material.dart';

import '../models/tactical/tactical_schema.dart';
import 'tactical_entities.dart';

class TacticalValidationResult {
  final bool ok;
  final List<String> errors;

  const TacticalValidationResult({required this.ok, this.errors = const []});
}

/// Rules from Phase 2: duplicate assignment, impossible movement, ball owner continuity.
TacticalValidationResult validatePlaybook(TacticalPlaybook book) {
  final errs = <String>[];
  var ball = 1;

  for (var i = 0; i < book.steps.length; i++) {
    final st = book.steps[i];
    if (st.actorSlot < 1 || st.actorSlot > 5) {
      errs.add('Step ${i + 1}: actor slot must be 1–5.');
    }
    if (st.targetSlot != null && (st.targetSlot! < 1 || st.targetSlot! > 5)) {
      errs.add('Step ${i + 1}: target slot must be 1–5.');
    }

    switch (st.kind) {
      case PlayStepKind.pass:
        if (st.actorSlot == st.targetSlot) {
          errs.add('Step ${i + 1}: pass needs two different players.');
        }
        if (st.actorSlot != ball) {
          errs.add('Step ${i + 1}: ball is with Player $ball, not ${st.actorSlot}.');
        }
        if (st.targetSlot != null) ball = st.targetSlot!;
        break;
      case PlayStepKind.shoot:
        if (st.actorSlot != ball) {
          errs.add('Step ${i + 1}: shooter must possess the ball (owner $ball).');
        }
        break;
      case PlayStepKind.screen:
      case PlayStepKind.cut:
      case PlayStepKind.dribble:
      case PlayStepKind.switchDefense:
      case PlayStepKind.inbound:
      case PlayStepKind.other:
        break;
    }

    if (st.toNorm != null) {
      final p = st.toNorm!;
      if (p.dx < 0 || p.dx > 1 || p.dy < 0 || p.dy > 1) {
        errs.add('Step ${i + 1}: movement target outside court (0–1).');
      }
    }
  }

  return TacticalValidationResult(ok: errs.isEmpty, errors: errs);
}

Offset clampNorm(Offset o) => Offset(o.dx.clamp(0.0, 1.0), o.dy.clamp(0.0, 1.0));
