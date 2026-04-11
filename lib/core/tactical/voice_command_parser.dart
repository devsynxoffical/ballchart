import '../models/tactical/tactical_schema.dart';
import 'tactical_entities.dart';

/// Parsed coach voice / text command with safety metadata.
class ParsedCoachCommand {
  final CoachIntent intent;
  final Map<String, dynamic> entities;
  final double confidence;
  final List<String> alternatives;
  final String? raw;

  const ParsedCoachCommand({
    required this.intent,
    this.entities = const {},
    this.confidence = 0,
    this.alternatives = const [],
    this.raw,
  });

  bool get needsConfirmation => confidence < 0.72 || alternatives.isNotEmpty;
}

enum CoachIntent {
  unknown,
  playerPass,
  zoneSwitch,
  runNamedPlay,
  markTurnover,
  markPossession,
}

/// Deterministic rule-based parser (Phase 4). Replace with ML / cloud NLU later.
ParsedCoachCommand parseCoachCommand(String input) {
  final s = input.trim().toLowerCase();
  if (s.isEmpty) {
    return const ParsedCoachCommand(intent: CoachIntent.unknown, confidence: 0, raw: '');
  }

  // "player 1 pass to player 2" / "p1 pass to p2"
  final passRe = RegExp(
    r'^(?:player\s*)?(\d)\s*(?:pass(?:es)?|throws?)\s*(?:to\s*)?(?:player\s*)?(\d)\b',
    caseSensitive: false,
  );
  final mPass = passRe.firstMatch(s);
  if (mPass != null) {
    final from = int.tryParse(mPass.group(1)!) ?? 1;
    final to = int.tryParse(mPass.group(2)!) ?? 2;
    if (from == to) {
      return ParsedCoachCommand(
        intent: CoachIntent.unknown,
        confidence: 0.35,
        alternatives: ['Player $from pass to Player ${to == from ? to + 1 : to}'],
        entities: {'from': from, 'to': to},
        raw: input,
      );
    }
    return ParsedCoachCommand(
      intent: CoachIntent.playerPass,
      confidence: 0.92,
      entities: {'from': from, 'to': to, 'stepKind': PlayStepKind.pass.name},
      raw: input,
    );
  }

  // "switch to 2-3 zone" / "2-3 zone"
  if (RegExp(r'(2[\s-]*3|two[\s-]*three)').hasMatch(s) && s.contains('zone')) {
    return ParsedCoachCommand(
      intent: CoachIntent.zoneSwitch,
      confidence: 0.88,
      entities: {'zone': '2-3', 'preset': FormationPreset.zone23.name},
      raw: input,
    );
  }
  if (RegExp(r'(3[\s-]*2|three[\s-]*two)').hasMatch(s) && s.contains('zone')) {
    return ParsedCoachCommand(
      intent: CoachIntent.zoneSwitch,
      confidence: 0.85,
      entities: {'zone': '3-2', 'preset': FormationPreset.zone32.name},
      raw: input,
    );
  }

  // "run fast break alpha" / "run play fast break alpha"
  final runRe = RegExp(r'run\s+(?:play\s+)?(?:fast\s+break\s+)?([a-z0-9\s]+)$', caseSensitive: false);
  final mRun = runRe.firstMatch(s);
  if (mRun != null && s.contains('run')) {
    final name = mRun.group(1)?.trim() ?? '';
    if (name.isNotEmpty) {
      return ParsedCoachCommand(
        intent: CoachIntent.runNamedPlay,
        confidence: name.length > 2 ? 0.82 : 0.55,
        entities: {'playName': name},
        alternatives: name.length < 3 ? ['Run fast break alpha', 'Run horns set'] : const [],
        raw: input,
      );
    }
  }

  // "mark possession turnover" / "turnover"
  if (s.contains('turnover')) {
    return ParsedCoachCommand(
      intent: CoachIntent.markTurnover,
      confidence: 0.9,
      entities: {'event': 'turnover'},
      raw: input,
    );
  }

  if (s.contains('possession')) {
    return ParsedCoachCommand(
      intent: CoachIntent.markPossession,
      confidence: 0.65,
      entities: {'event': 'possession'},
      alternatives: const ['Mark possession turnover'],
      raw: input,
    );
  }

  return ParsedCoachCommand(
    intent: CoachIntent.unknown,
    confidence: 0.2,
    alternatives: const [
      'Player 1 pass to Player 2',
      'Switch to 2-3 zone',
      'Run fast break alpha',
      'Mark possession turnover',
    ],
    raw: input,
  );
}
