import 'voice_command_parser.dart';

/// Human-readable “what’s happening on the floor” after speech/text (STT → intent → scenario).
class ScenarioSummary {
  final String headline;
  final List<String> bullets;
  final String phase;

  const ScenarioSummary({
    required this.headline,
    this.bullets = const [],
    this.phase = 'open_play',
  });
} 

/// Builds coaching-style scenario text from raw utterance + parsed intent.
ScenarioSummary interpretScenario(String raw, ParsedCoachCommand parsed) {
  final t = raw.trim();
  if (t.isEmpty) {
    return const ScenarioSummary(
      headline: 'No command yet',
      bullets: ['Speak or type a tactical command.'],
      phase: 'idle',
    );
  }

















































































































  switch (parsed.intent) {
    case CoachIntent.sequence:
      return ScenarioSummary(
        headline: 'Multi-step tactical flow',
        phase: 'complex_play',
        bullets: [
          'Processing ${parsed.steps.length} sequential actions.',
          'Players will move and pass in the exact order you described.',
          'Watch the simulation play out step-by-step on the board.',
        ],
      );
    case CoachIntent.playerPass:
      final from = (parsed.entities['from'] as num?)?.toInt() ?? (parsed.entities['actor'] as num?)?.toInt() ?? 1;
      final to = (parsed.entities['to'] as num?)?.toInt() ?? (parsed.entities['target'] as num?)?.toInt() ?? 2;
      final action = parsed.entities['action']?.toString() ?? (parsed.entities['isHandoff'] == true ? 'handoff' : 'pass');
      
      String headline = 'Half-court possession — $action';
      List<String> bullets = [
        'Offense (bottom end) has the ball; defense (top end) is set in shell.',
        'Action: Player $from is executing a $action to Player $to.',
      ];

      if (action == 'screen') {
        bullets.add('Screener (P$from) should hold the angle to force the defender over/under.');
      } else if (action == 'shoot') {
        headline = 'Shot attempt — Player $from';
        bullets = ['Player $from is taking a high-percentage look at the basket.'];
      }

      return ScenarioSummary(
        headline: headline,
        phase: 'half_court_offense',
        bullets: bullets,
      );
    case CoachIntent.zoneSwitch:
      final z = parsed.entities['zone']?.toString() ?? '2-3';
      return ScenarioSummary(
        headline: 'Defense — $z zone look',
        phase: 'defense_zone',
        bullets: [
          'Defense shifts to a $z alignment: top defenders take away high post entry.',
          'Offense should look for short corner skips and high-low vs the overload.',
        ],
      );
    case CoachIntent.runNamedPlay:
      final name = parsed.entities['playName']?.toString() ?? 'called set';
      return ScenarioSummary(
        headline: 'Set play: “$name”',
        phase: 'set_play',
        bullets: [
          'Teams align in a scripted formation; first look is often a wing or pin-down.',
          'If denied, flow into secondary action (handoff or Spain pick).',
        ],
      );
    case CoachIntent.markTurnover:
      return const ScenarioSummary(
        headline: 'Live-ball turnover — scramble',
        phase: 'transition',
        bullets: [
          'Possession just changed; ball is loose / reset at mid-court in the lab.',
          'Next phase: sprint back on D or push tempo on O depending on your rules.',
        ],
      );
    case CoachIntent.markPossession:
      return const ScenarioSummary(
        headline: 'Possession context',
        phase: 'possession',
        bullets: [
          'Use this when clarifying who has the ball in a dead-ball or jump-ball situation.',
        ],
      );
    case CoachIntent.unknown:
      final lower = t.toLowerCase();
      if (lower.contains('shoot') || lower.contains('shot')) {
        return ScenarioSummary(
          headline: 'Shot attempt (inferred)',
          phase: 'half_court_offense',
          bullets: [
            'Likely a scoring action — close out discipline and box-out priority.',
            'If you meant a specific player shot, we’ll add “Player X shoots” to the parser next.',
          ],
        );
      }
      if (lower.contains('screen') || lower.contains('pick')) {
        return ScenarioSummary(
          headline: 'Screen / pick action (inferred)',
          phase: 'half_court_offense',
          bullets: [
            'Two players involved: screener and handler; defense may switch, ice, or under.',
          ],
        );
      }
      final tips = <String>[
        'Try: “Player 1 pass to Player 2”, “Switch to 2-3 zone”, “Run fast break alpha”, or “Mark possession turnover”.',
      ];
      if (parsed.alternatives.isNotEmpty) {
        tips.add('Quick picks: ${parsed.alternatives.take(2).join(' · ')}');
      }
      return ScenarioSummary(
        headline: 'Scenario not recognized yet',
        phase: 'unknown',
        bullets: tips,
      );
  }
}
