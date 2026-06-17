import 'package:flutter/material.dart';
import '../models/tactical/tactical_schema.dart';
import 'tactical_entities.dart';

/// Parsed coach voice / text command with safety metadata.
class ParsedCoachCommand {
  final CoachIntent intent;
  final Map<String, dynamic> entities;
  final double confidence;
  final List<String> alternatives;
  final String? raw;
  final List<PlayStep> steps;

  const ParsedCoachCommand({
    required this.intent,
    this.entities = const {},
    this.confidence = 0,
    this.alternatives = const [],
    this.raw,
    this.steps = const [],
  });

  bool get needsConfirmation => confidence < 0.72 || alternatives.isNotEmpty;

  factory ParsedCoachCommand.fromJson(Map<String, dynamic> j, String rawInput) {
    final intentName = j['intent']?.toString() ?? 'unknown';
    final intent = CoachIntent.values.firstWhere(
      (e) => e.name == intentName,
      orElse: () => CoachIntent.unknown,
    );

    final stepsList = <PlayStep>[];
    final stepsRaw = j['steps'];
    if (stepsRaw is List) {
      for (final s in stepsRaw) {
        if (s is Map) {
          stepsList.add(PlayStep.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    final alternativesList = <String>[];
    final alts = j['alternatives'];
    if (alts is List) {
      for (final a in alts) {
        alternativesList.add(a.toString());
      }
    }

    return ParsedCoachCommand(
      intent: intent,
      entities: j['entities'] is Map ? Map<String, dynamic>.from(j['entities']) : const {},
      confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
      alternatives: alternativesList,
      raw: rawInput,
      steps: stepsList,
    );
  }
}

enum CoachIntent {
  unknown,
  sequence,
  playerPass,
  zoneSwitch,
  runNamedPlay,
  markTurnover,
  markPossession,
}

// --- Token Types ---
enum TokenType { actor, action, area, delimiter }

class Token {
  final TokenType type;
  final dynamic value;
  const Token(this.type, this.value);
}

class ActorVal {
  final int slot;
  final bool isDef;
  const ActorVal(this.slot, this.isDef);
}

/// Token-based State Machine Parser (Replaces Regex)
ParsedCoachCommand parseCoachCommand(String input) {
  final raw = input.trim().toLowerCase();
  if (raw.isEmpty) {
    return const ParsedCoachCommand(intent: CoachIntent.unknown, confidence: 0, raw: '');
  }

  // 1. Check for specific non-step intents first
  if (RegExp(r'(2[\s-]*3|two[\s-]*three)').hasMatch(raw) && raw.contains('zone')) {
    return ParsedCoachCommand(
      intent: CoachIntent.zoneSwitch,
      confidence: 0.88,
      entities: {'preset': FormationPreset.zone23.name, 'zone': '2-3'},
      raw: input,
    );
  }

  // Check for run play
  final runRe = RegExp(r'run\s+(?:play\s+)?(?:fast\s+break\s+)?([a-z0-9\s]+)$', caseSensitive: false);
  final mRun = runRe.firstMatch(raw);
  if (mRun != null && raw.contains('run')) {
    final name = mRun.group(1)?.trim() ?? '';
    if (name.isNotEmpty) {
      return ParsedCoachCommand(
        intent: CoachIntent.runNamedPlay,
        confidence: name.length > 2 ? 0.82 : 0.55,
        entities: {'playName': name},
        alternatives: name.length < 3 ? ['Run horns pick and roll', 'Run transition lane'] : const [],
        raw: input,
      );
    }
  }

  // Check for turnover
  if (raw.contains('turnover')) {
    return ParsedCoachCommand(
      intent: CoachIntent.markTurnover,
      confidence: 0.9,
      entities: {'event': 'turnover'},
      raw: input,
    );
  }

  // Check for possession
  if (raw.contains('possession')) {
    return ParsedCoachCommand(
      intent: CoachIntent.markPossession,
      confidence: 0.65,
      entities: {'event': 'possession'},
      alternatives: const ['Mark possession turnover'],
      raw: input,
    );
  }

  // 2. Tokenize Input
  final tokens = _tokenize(raw);
  if (tokens.isEmpty) {
    return ParsedCoachCommand(intent: CoachIntent.unknown, confidence: 0, raw: input);
  }

  // 3. State Machine Execution
  final steps = <PlayStep>[];
  ActorVal? currentActor;
  ActionTokenVal? currentAction;
  
  void flushStep(ActorVal? targetActor, Offset? targetArea) {
    if (currentAction == null || currentActor == null) return;

    PlayStepKind kind = currentAction!.kind;
    
    // Adjust kind based on context
    if (kind == PlayStepKind.cut && targetActor != null) {
      // "move to P2" -> essentially setting a screen or moving towards them. We map to cut.
    }

    final step = PlayStep(
      id: 'step_${steps.length + 1}',
      kind: kind,
      actorSlot: currentActor!.slot,
      isDefense: currentActor!.isDef,
      targetSlot: targetActor?.slot,
      targetIsDefense: targetActor?.isDef ?? false,
      toNorm: targetArea,
    );
    steps.add(step);
    
    // State transitions for implied subjects
    if (kind == PlayStepKind.pass && targetActor != null) {
      currentActor = targetActor; // Receiver becomes next actor implicitly
    }
    
    currentAction = null;
  }

  for (int i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    
    if (t.type == TokenType.delimiter) {
      // Delimiter means we might have a pending action that doesn't need targets (like shoot)
      if (currentAction != null && currentAction!.kind == PlayStepKind.shoot) {
        flushStep(null, null);
      }
      continue;
    }

    if (t.type == TokenType.actor) {
      final act = t.value as ActorVal;
      if (currentAction == null) {
        // New subject
        currentActor = act;
      } else {
        // Target subject
        flushStep(act, null);
      }
    } else if (t.type == TokenType.action) {
      final act = t.value as ActionTokenVal;
      
      // If we already have a pending action, flush it (e.g., "P1 shoot P2 shoot")
      if (currentAction != null) {
        if (currentAction!.kind == PlayStepKind.shoot) {
          flushStep(null, null);
        } else {
          // If we had a pending "move" but no area, just ignore it and overwrite
        }
      }
      
      currentAction = act;
      
      // Shoot is an immediate action without targets
      if (act.kind == PlayStepKind.shoot) {
        flushStep(null, null);
      }
    } else if (t.type == TokenType.area) {
      final area = t.value as Offset;
      if (currentAction != null) {
        flushStep(null, area);
      } else if (currentActor != null) {
        // Implied move if just saying "P1 corner"
        currentAction = const ActionTokenVal(PlayStepKind.cut);
        flushStep(null, area);
      }
    }
  }

  // Final flush for trailing actions
  if (currentAction != null && currentAction!.kind == PlayStepKind.shoot) {
    flushStep(null, null);
  }

  if (steps.isNotEmpty) {
    final Map<String, dynamic> entities = {};
    if (steps.length == 1 && steps.first.kind == PlayStepKind.pass) {
      entities['from'] = steps.first.actorSlot;
      entities['to'] = steps.first.targetSlot;
    }
    return ParsedCoachCommand(
      intent: steps.length > 1 ? CoachIntent.sequence : CoachIntent.playerPass,
      confidence: 0.9,
      steps: steps,
      raw: input,
      entities: entities,
    );
  }

  return ParsedCoachCommand(intent: CoachIntent.unknown, confidence: 0.2, raw: input);
}

class ActionTokenVal {
  final PlayStepKind kind;
  const ActionTokenVal(this.kind);
}

List<Token> _tokenize(String input) {
  final tokens = <Token>[];
  // Replace punctuation with spaces to treat commas as words
  var s = input.replaceAll(',', ' , ').replaceAll(';', ' ; ').replaceAll('.', ' . ');
  final words = s.split(RegExp(r'\s+'));

  for (int i = 0; i < words.length; i++) {
    final w = words[i];
    if (w.isEmpty) continue;

    // 1. Delimiters
    if (w == ',' || w == ';' || w == '.' || w == 'then' || w == 'next' || w == 'and') {
      tokens.add(const Token(TokenType.delimiter, null));
      continue;
    }
 
    // 2. Actors (P1, O2, D3, player 1, player one, or just 1)
    final pMatch = RegExp(r'^(o|d|p)?([1-5])$').firstMatch(w);
    if (pMatch != null) {
      final prefix = pMatch.group(1);
      final isDef = prefix == 'd';
      final slot = int.parse(pMatch.group(2)!);
      tokens.add(Token(TokenType.actor, ActorVal(slot, isDef)));
      continue;
    }
    final bareNum = RegExp(r'^([1-5])$').firstMatch(w);
    if (bareNum != null) {
      tokens.add(Token(TokenType.actor, ActorVal(int.parse(bareNum.group(1)!), false)));
      continue;
    }
    if ((w == 'player' || w == 'number' || w == 'offense') && i + 1 < words.length) {
      final next = words[i + 1];
      final numMatch = RegExp(r'^([1-5])$').firstMatch(next);
      if (numMatch != null) {
        tokens.add(Token(TokenType.actor, ActorVal(int.parse(numMatch.group(1)!), false)));
        i++;
        continue;
      }
    }
    if ((w == 'defense' || w == 'defender') && i + 1 < words.length) {
      final next = words[i + 1];
      final numMatch = RegExp(r'^([1-5])$').firstMatch(next);
      if (numMatch != null) {
        tokens.add(Token(TokenType.actor, ActorVal(int.parse(numMatch.group(1)!), true)));
        i++;
        continue;
      }
    }

    // 3. Actions
    if (RegExp(r'^(pass(es)?|throw(s)?|give(s)?)$').hasMatch(w)) {
      tokens.add(const Token(TokenType.action, ActionTokenVal(PlayStepKind.pass)));
      continue;
    }
    if (RegExp(r'^(handoff(s)?|hand(s)?)$').hasMatch(w)) {
      tokens.add(const Token(TokenType.action, ActionTokenVal(PlayStepKind.handoff)));
      continue;
    }
    if (RegExp(r'^(shoot(s)?|score(s)?|shot)$').hasMatch(w)) {
      tokens.add(const Token(TokenType.action, ActionTokenVal(PlayStepKind.shoot)));
      continue;
    }
    if (RegExp(r'^(move(s)?|cut(s)?|run(s)?|go(es)?|sprint(s)?)$').hasMatch(w)) {
      tokens.add(const Token(TokenType.action, ActionTokenVal(PlayStepKind.cut)));
      continue;
    }
    if (RegExp(r'^(screen(s)?|pick(s)?|set(s)?)$').hasMatch(w)) {
      tokens.add(const Token(TokenType.action, ActionTokenVal(PlayStepKind.screen)));
      continue;
    }
    if (RegExp(r'^(roll(s)?)$').hasMatch(w)) {
      tokens.add(const Token(TokenType.action, ActionTokenVal(PlayStepKind.roll)));
      continue;
    }
    if (RegExp(r'^(pop(s)?)$').hasMatch(w)) {
      tokens.add(const Token(TokenType.action, ActionTokenVal(PlayStepKind.pop)));
      continue;
    }
    if (RegExp(r'^(drive(s)?)$').hasMatch(w)) {
      tokens.add(const Token(TokenType.action, ActionTokenVal(PlayStepKind.drive)));
      continue;
    }
    if (RegExp(r'^(flare(s)?|lift(s)?)$').hasMatch(w)) {
      tokens.add(const Token(TokenType.action, ActionTokenVal(PlayStepKind.flare)));
      continue;
    }

    // 4. Basketball court areas (offense attacks south hoop, y → 1)
    if (w == 'basket' || w == 'hoop' || w == 'rim' || w == 'bucket') {
      tokens.add(const Token(TokenType.area, Offset(0.5, 0.90)));
      continue;
    }
    if (w == 'wing') {
      tokens.add(const Token(TokenType.area, Offset(0.82, 0.70)));
      continue;
    }
    if (w == 'corner') {
      tokens.add(const Token(TokenType.area, Offset(0.92, 0.88)));
      continue;
    }
    if (w == 'elbow') {
      tokens.add(const Token(TokenType.area, Offset(0.72, 0.68)));
      continue;
    }
    if (w == 'top' || w == 'point') {
      tokens.add(const Token(TokenType.area, Offset(0.5, 0.72)));
      continue;
    }
    if (w == 'key' || w == 'paint' || w == 'block' || w == 'low') {
      tokens.add(const Token(TokenType.area, Offset(0.5, 0.85)));
      continue;
    }
    if (w == 'short') {
      tokens.add(const Token(TokenType.area, Offset(0.18, 0.78)));
      continue;
    }
  }

  return tokens;
}
