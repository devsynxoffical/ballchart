/// Phase 1 foundation: shared vocabulary for Strategy + Battle + future animation/voice.
/// Backend contracts can mirror these names over time.

/// Strategy document lifecycle (draft → published → archived).
enum StrategyRevisionState {
  draft,
  published,
  archived,
}

/// High-level strategy category (aligns with UI filters / tags).
enum StrategyPlayCategory {
  offense,
  defense,
  transition,
  inbound,
  press,
  situational,
}

/// Atomic step in a playbook sequence (future: ties to animation nodes).
enum PlayStepKind {
  pass,
  screen,
  cut,
  shoot,
  dribble,
  switchDefense,
  inbound,
  flare,
  staggerScreen,
  handoff,
  pickAndRoll,
  roll,
  pop,
  drive,
  spacing,
  other,
}

/// Battle session lifecycle for execution + tracking (Phase 3).
enum BattleSessionPhase {
  scheduled,
  live,
  paused,
  finished,
}

/// Normalizes API `status` + optional `metadata['sessionPhase']` to a phase for UI.
BattleSessionPhase battlePhaseFromModel({
  required String status,
  Map<String, dynamic>? metadata,
}) {
  final paused = metadata?['sessionPhase']?.toString() == 'paused';
  if (paused) return BattleSessionPhase.paused;
  switch (status) {
    case 'ongoing':
      return BattleSessionPhase.live;
    case 'finished':
    case 'cancelled':
      return BattleSessionPhase.finished;
    case 'pending':
    default:
      return BattleSessionPhase.scheduled;
  }
}
