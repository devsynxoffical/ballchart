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

  // Suggesting complete flows as requested by the user
  out.add(TacticalSuggestion(
    title: 'Strong Side Clear-out',
    reason: 'Create space for Player $ballOwnerSlot to drive by clearing the paint.',
    sampleCommand: 'Player 5 move to the basket then player $ballOwnerSlot pass to 2 then player 2 shoot',
  ));

  out.add(TacticalSuggestion(
    title: 'Pick and Roll Flow',
    reason: 'Use a high screen to force defensive help and find the open cutter.',
    sampleCommand: 'Player 4 move to player $ballOwnerSlot then player $ballOwnerSlot move close to goal then player 4 shoot',
  ));

  out.add(const TacticalSuggestion(
    title: 'Fast Break Transition',
    reason: 'Push the tempo immediately to catch the defense before they set up.',
    sampleCommand: 'Player 1 pass to player 3 then player 3 move to basket then player 3 shoot',
  ));

  return out;
}

String explainPlayStep(PlayStep step) {
  switch (step.kind) {
    case PlayStepKind.pass:
      return 'Moving the ball stresses the defense and creates open shooting windows.';
    case PlayStepKind.cut:
      return 'Cutting behind the defense catches defenders off-balance.';
    case PlayStepKind.shoot:
      return 'Finalizing the play with a high-percentage look at the rim.';
    default:
      return 'Tactical execution requires perfect timing and spatial awareness.';
  }
}
