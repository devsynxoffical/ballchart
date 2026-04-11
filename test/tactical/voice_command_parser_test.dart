import 'package:flutter_test/flutter_test.dart';
import 'package:ballchart/core/tactical/voice_command_parser.dart';

void main() {
  group('parseCoachCommand', () {
    test('pass intent', () {
      final p = parseCoachCommand('Player 1 pass to Player 2');
      expect(p.intent, CoachIntent.playerPass);
      expect(p.confidence, greaterThan(0.85));
      expect(p.entities['from'], 1);
      expect(p.entities['to'], 2);
    });

    test('2-3 zone', () {
      final p = parseCoachCommand('Switch to 2-3 zone');
      expect(p.intent, CoachIntent.zoneSwitch);
      expect(p.entities['zone'], '2-3');
    });

    test('run play', () {
      final p = parseCoachCommand('Run fast break alpha');
      expect(p.intent, CoachIntent.runNamedPlay);
      expect(p.entities['playName'], isNotEmpty);
    });

    test('turnover', () {
      final p = parseCoachCommand('Mark possession turnover');
      expect(p.intent, CoachIntent.markTurnover);
    });
  });
}
