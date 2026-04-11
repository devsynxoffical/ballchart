import 'package:flutter/material.dart';

import '../models/tactical/tactical_schema.dart';

/// Serializable playbook step (maps to animation + backend `metadata.playSteps`).
class PlayStep {
  final String id;
  final PlayStepKind kind;
  /// 1-based slot index on court (see [CourtSlots]).
  final int actorSlot;
  final int? targetSlot;
  final String? note;
  /// Normalized destination override (optional).
  final Offset? toNorm;

  const PlayStep({
    required this.id,
    required this.kind,
    required this.actorSlot,
    this.targetSlot,
    this.note,
    this.toNorm,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'actorSlot': actorSlot,
        if (targetSlot != null) 'targetSlot': targetSlot,
        if (note != null) 'note': note,
        if (toNorm != null) 'toNorm': {'dx': toNorm!.dx, 'dy': toNorm!.dy},
      };

  factory PlayStep.fromJson(Map<String, dynamic> j) {
    Offset? tn;
    final t = j['toNorm'];
    if (t is Map) {
      tn = Offset(
        (t['dx'] as num?)?.toDouble() ?? 0,
        (t['dy'] as num?)?.toDouble() ?? 0,
      );
    }
    return PlayStep(
      id: (j['id'] ?? '').toString(),
      kind: PlayStepKind.values.firstWhere(
        (e) => e.name == j['kind'],
        orElse: () => PlayStepKind.other,
      ),
      actorSlot: (j['actorSlot'] as num?)?.toInt() ?? 1,
      targetSlot: (j['targetSlot'] as num?)?.toInt(),
      note: j['note']?.toString(),
      toNorm: tn,
    );
  }
}

/// Named formation presets (slot layout only; defense sets similar grids).
enum FormationPreset {
  man23,
  man32,
  zone23,
  zone32,
  fastBreak,
  press,
}

/// Strategy document with versioning and tactical payload (stored under Strategy.metadata).
class TacticalPlaybook {
  final StrategyRevisionState revisionState;
  final FormationPreset formation;
  final List<PlayStep> steps;
  final List<String> tags;
  final String? opponentArchetype;

  const TacticalPlaybook({
    required this.revisionState,
    required this.formation,
    required this.steps,
    this.tags = const [],
    this.opponentArchetype,
  });

  Map<String, dynamic> toJson() => {
        'revisionState': revisionState.name,
        'formation': formation.name,
        'playSteps': steps.map((e) => e.toJson()).toList(),
        'tags': tags,
        if (opponentArchetype != null) 'opponentArchetype': opponentArchetype,
      };

  factory TacticalPlaybook.fromJson(Map<String, dynamic> j) {
    final raw = j['playSteps'];
    final steps = <PlayStep>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) steps.add(PlayStep.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return TacticalPlaybook(
      revisionState: StrategyRevisionState.values.firstWhere(
        (e) => e.name == j['revisionState'],
        orElse: () => StrategyRevisionState.draft,
      ),
      formation: FormationPreset.values.firstWhere(
        (e) => e.name == j['formation'],
        orElse: () => FormationPreset.man23,
      ),
      steps: steps,
      tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      opponentArchetype: j['opponentArchetype']?.toString(),
    );
  }
}

/// Battle-side event log entry (persisted under Battle.metadata.events or top-level events).
class BattleEvent {
  final String id;
  final DateTime at;
  final String type;
  final Map<String, dynamic> payload;

  const BattleEvent({
    required this.id,
    required this.at,
    required this.type,
    this.payload = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'type': type,
        'payload': payload,
      };
}

/// Single animation / command node on the shared timeline.
class TimelineAction {
  final String id;
  final Duration at;
  final String source;
  final PlayStepKind kind;
  final Map<String, dynamic> data;

  const TimelineAction({
    required this.id,
    required this.at,
    required this.source,
    required this.kind,
    this.data = const {},
  });
}
