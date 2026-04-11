import '../models/tactical/tactical_schema.dart';
import 'tactical_entities.dart';

/// Phase 6 — lightweight, explainable heuristics (no network). Swap for LLM + RAG later.
class TacticalSuggestion {
  final String title;
  final String reason;
  final String sampleCommand;

  const TacticalSuggestion({
    required this.title,
    required this.reason,
    required this.sampleCommand,
  });
}

List<TacticalSuggestion> suggestNextActions({
  required FormationPreset formation,
  required int ballOwnerSlot,
  List<String> recentEvents = const [],
}) {
  final out = <TacticalSuggestion>[];

  if (recentEvents.any((e) => e.contains('turnover'))) {
    out.add(const TacticalSuggestion(
      title: 'Reset to half-court',
      reason: 'After a turnover, spacing often collapses; reset to 2-3 zone or horns.',
      sampleCommand: 'Switch to 2-3 zone',
    ));
  }

  if (formation == FormationPreset.fastBreak) {
    out.add(const TacticalSuggestion(
      title: 'Pitch ahead',
      reason: 'Fast break alignment rewards early lane fill and quick pass.',
      sampleCommand: 'Player 1 pass to Player 2',
    ));
  } else {
    out.add(TacticalSuggestion(
      title: 'Probe weak side',
      reason: 'Ball is with Player $ballOwnerSlot; reverse or skip to shift the help line.',
      sampleCommand: 'Player $ballOwnerSlot pass to Player ${ballOwnerSlot % 5 + 1}',
    ));
  }

  out.add(const TacticalSuggestion(
    title: 'Call set play',
    reason: 'Late-clock: use a named set to get a clean look.',
    sampleCommand: 'Run fast break alpha',
  ));

  return out;
}

String explainPlayStep(PlayStep step) {
  switch (step.kind) {
    case PlayStepKind.pass:
      return 'Because the defense shifts to the strong side, reversing the ball stresses the help.';
    case PlayStepKind.screen:
      return 'The screen forces a switch or hedge, opening a driving lane.';
    case PlayStepKind.cut:
      return 'Cutting when the defender ball-watches creates a back-door window.';
    case PlayStepKind.shoot:
      return 'Shot quality improves when feet are set after the drive kick.';
    default:
      return 'Tactical timing depends on defender positioning and ball pressure.';
  }
}
