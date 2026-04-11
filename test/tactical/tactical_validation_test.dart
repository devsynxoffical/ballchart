import 'package:flutter_test/flutter_test.dart';
import 'package:ballchart/core/models/tactical/tactical_schema.dart';
import 'package:ballchart/core/tactical/tactical_entities.dart';
import 'package:ballchart/core/tactical/tactical_validation.dart';

void main() {
  test('validatePlaybook catches pass without ball', () {
    final book = TacticalPlaybook(
      revisionState: StrategyRevisionState.draft,
      formation: FormationPreset.man23,
      steps: [
        PlayStep(id: '1', kind: PlayStepKind.pass, actorSlot: 2, targetSlot: 3),
      ],
    );
    final r = validatePlaybook(book);
    expect(r.ok, isFalse);
    expect(r.errors.any((e) => e.contains('ball')), isTrue);
  });

  test('validatePlaybook ok for valid pass chain', () {
    final book = TacticalPlaybook(
      revisionState: StrategyRevisionState.draft,
      formation: FormationPreset.man23,
      steps: [
        PlayStep(id: '1', kind: PlayStepKind.pass, actorSlot: 1, targetSlot: 2),
        PlayStep(id: '2', kind: PlayStepKind.pass, actorSlot: 2, targetSlot: 3),
      ],
    );
    final r = validatePlaybook(book);
    expect(r.ok, isTrue);
  });
}
