import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../models/tactical/tactical_schema.dart';
import 'court_geometry.dart';
import 'tactical_entities.dart';
import 'voice_command_parser.dart';

/// Full court: 5 offense + 5 defense + ball (normalized 0–1, north→south).
class TacticalFrame {
  final List<Offset> offenseNorm;
  final List<Offset> defenseNorm;
  final Offset ballNorm;
  final FormationPreset formation;

  const TacticalFrame({
    required this.offenseNorm,
    required this.defenseNorm,
    required this.ballNorm,
    required this.formation,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TacticalFrame &&
        formation == other.formation &&
        ballNorm == other.ballNorm &&
        listEquals(offenseNorm, other.offenseNorm) &&
        listEquals(defenseNorm, other.defenseNorm);
  }

  @override
  int get hashCode => Object.hash(formation, ballNorm, Object.hashAll(offenseNorm), Object.hashAll(defenseNorm));
}

/// Drives animation from voice commands and playbook steps (Phase 5).
class TacticalPlaybackController extends ChangeNotifier {
  TacticalPlaybackController({FormationPreset formation = FormationPreset.man23}) : _formation = formation {
    final layout = CourtSlots.fullCourt(formation);
    _offense = List<Offset>.from(layout.offense);
    _defense = List<Offset>.from(layout.defense);
    _ball = _offense[CourtSlots.slotToIndex(1)];
  }

  FormationPreset _formation;
  late List<Offset> _offense;
  late List<Offset> _defense;
  late Offset _ball;
  int _ballOwnerSlot = 1;
  final List<TimelineAction> _timeline = [];

  FormationPreset get formation => _formation;
  TacticalFrame get frame => TacticalFrame(
        offenseNorm: List.unmodifiable(_offense),
        defenseNorm: List.unmodifiable(_defense),
        ballNorm: _ball,
        formation: _formation,
      );
  List<TimelineAction> get timeline => List.unmodifiable(_timeline);
  int get ballOwnerSlot => _ballOwnerSlot;

  void _applyLayout(FormationPreset f) {
    final layout = CourtSlots.fullCourt(f);
    _offense = List<Offset>.from(layout.offense);
    _defense = List<Offset>.from(layout.defense);
    _ball = _offense[CourtSlots.slotToIndex(_ballOwnerSlot.clamp(1, 5))];
  }

  void setFormation(FormationPreset f) {
    _formation = f;
    _applyLayout(f);
    notifyListeners();
  }

  void applyParsedCommand(ParsedCoachCommand cmd) {
    switch (cmd.intent) {
      case CoachIntent.playerPass:
        final from = (cmd.entities['from'] as num?)?.toInt() ?? 1;
        final to = (cmd.entities['to'] as num?)?.toInt() ?? 2;
        _pass(from, to);
        break;
      case CoachIntent.zoneSwitch:
        final preset = cmd.entities['preset']?.toString();
        final f = FormationPreset.values.firstWhere(
          (e) => e.name == preset,
          orElse: () => FormationPreset.zone23,
        );
        setFormation(f);
        _pushTimeline(PlayStepKind.other, {'action': 'zoneSwitch', 'preset': f.name});
        break;
      case CoachIntent.runNamedPlay:
        _pushTimeline(PlayStepKind.other, {'action': 'runPlay', 'name': cmd.entities['playName']});
        notifyListeners();
        break;
      case CoachIntent.markTurnover:
        _ball = const Offset(0.5, 0.5);
        _pushTimeline(PlayStepKind.other, {'event': 'turnover'});
        notifyListeners();
        break;
      case CoachIntent.markPossession:
        _pushTimeline(PlayStepKind.other, {'event': 'possession'});
        notifyListeners();
        break;
      case CoachIntent.unknown:
        notifyListeners();
        break;
    }
  }

  void applyPlayStep(PlayStep step) {
    switch (step.kind) {
      case PlayStepKind.pass:
        if (step.targetSlot != null) _pass(step.actorSlot, step.targetSlot!);
        break;
      case PlayStepKind.cut:
        if (step.toNorm != null && step.actorSlot >= 1 && step.actorSlot <= 5) {
          final i = CourtSlots.slotToIndex(step.actorSlot);
          _offense[i] = step.toNorm!;
        }
        notifyListeners();
        break;
      case PlayStepKind.shoot:
      case PlayStepKind.screen:
      case PlayStepKind.dribble:
      case PlayStepKind.switchDefense:
      case PlayStepKind.inbound:
      case PlayStepKind.other:
        _pushTimeline(step.kind, {'actor': step.actorSlot});
        notifyListeners();
        break;
    }
  }

  void _pass(int fromSlot, int toSlot) {
    if (!isValidSlot(fromSlot) || !isValidSlot(toSlot)) return;
    final toI = CourtSlots.slotToIndex(toSlot);
    if (_ballOwnerSlot != fromSlot) {
      _pushTimeline(PlayStepKind.pass, {'warn': 'ball_mismatch', 'owner': _ballOwnerSlot, 'from': fromSlot});
    }
    _ball = _offense[toI];
    _ballOwnerSlot = toSlot;
    _pushTimeline(PlayStepKind.pass, {'from': fromSlot, 'to': toSlot});
    notifyListeners();
  }

  void _pushTimeline(PlayStepKind kind, Map<String, dynamic> data) {
    _timeline.add(TimelineAction(
      id: 't_${_timeline.length}',
      at: Duration(milliseconds: 20 * _timeline.length),
      source: 'engine',
      kind: kind,
      data: data,
    ));
  }

  bool isValidSlot(int s) => s >= 1 && s <= 5;

  void reset() {
    _formation = FormationPreset.man23;
    _ballOwnerSlot = 1;
    _applyLayout(_formation);
    _timeline.clear();
    notifyListeners();
  }
}
