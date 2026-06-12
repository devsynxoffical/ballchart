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
    title: 'Strong-side clear-out',
    reason: 'Empty the strong-side block so P$ballOwnerSlot can attack the rim.',
    sampleCommand: 'Player 5 move to corner then player $ballOwnerSlot drive to paint then player $ballOwnerSlot pass to 2 then player 2 shoot',
  ));

  out.add(TacticalSuggestion(
    title: 'High pick-and-roll',
    reason: 'Set a ball screen at the top and roll to the rim for a lob or kick-out.',
    sampleCommand: 'Player 5 screen player $ballOwnerSlot then player 5 roll to basket then player $ballOwnerSlot pass to 5',
  ));

  out.add(const TacticalSuggestion(
    title: 'Transition lane fill',
    reason: 'Fill the wide lane in transition before the defense recovers.',
    sampleCommand: 'Player 1 pass to player 3 then player 3 cut to basket then player 3 shoot',
  ));

  out.add(const TacticalSuggestion(
    title: 'Zone skip pass',
    reason: 'Shift the zone with a dribble, then skip to the weak-side corner three.',
    sampleCommand: 'Player 2 move to wing then player 1 pass to 2 then player 2 shoot',
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
