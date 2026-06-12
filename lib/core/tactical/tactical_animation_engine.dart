import 'dart:async';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/tactical/tactical_schema.dart';
import 'court_geometry.dart';
import 'tactical_entities.dart';
import 'voice_command_parser.dart';

class TacticalFrame {
  final List<Offset> offenseNorm;
  final List<Offset> defenseNorm;
  final Offset ballNorm;
  final FormationPreset formation;
  
  // Optional start/target states for drawing paths
  final List<Offset>? startOffenseNorm;
  final List<Offset>? startDefenseNorm;
  final Offset? startBallNorm;
  final List<Offset>? targetOffenseNorm;
  final List<Offset>? targetDefenseNorm;
  final Offset? targetBallNorm;

  const TacticalFrame({
    required this.offenseNorm,
    required this.defenseNorm,
    required this.ballNorm,
    required this.formation,
    this.startOffenseNorm,
    this.startDefenseNorm,
    this.startBallNorm,
    this.targetOffenseNorm,
    this.targetDefenseNorm,
    this.targetBallNorm,
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

class TacticalPlaybackController extends ChangeNotifier {
  TacticalPlaybackController({FormationPreset formation = FormationPreset.man23}) : _formation = formation {
    final layout = CourtSlots.fullCourt(formation);
    _offense = List<Offset>.from(layout.offense);
    _defense = List<Offset>.from(layout.defense);
    _ball = _offense[CourtSlots.slotToIndex(1)];
    
    _curOffense = List<Offset>.from(_offense);
    _curDefense = List<Offset>.from(_defense);
    _curBall = _ball;

    _ticker = Ticker(_onTick);
  }

  FormationPreset _formation;
  late List<Offset> _offense; // Target positions
  late List<Offset> _defense;
  late Offset _ball;
  
  late List<Offset> _curOffense; // Current interpolated positions
  late List<Offset> _curDefense;
  late Offset _curBall;

  late List<Offset> _startOffense; // Start positions for current interpolation
  late List<Offset> _startDefense;
  late Offset _startBall;

  int _ballOwnerSlot = 1;
  final List<PlayStep> _stepQueue = [];
  final List<PlayStep> _recordedSteps = [];
  bool _isAnimating = false;
  late Ticker _ticker;
  
  final List<TimelineAction> _timeline = [];

  FormationPreset get formation => _formation;
  TacticalFrame get frame => TacticalFrame(
        offenseNorm: List.unmodifiable(_curOffense),
        defenseNorm: List.unmodifiable(_curDefense),
        ballNorm: _curBall,
        formation: _formation,
        startOffenseNorm: _isAnimating ? List.unmodifiable(_startOffense) : null,
        startDefenseNorm: _isAnimating ? List.unmodifiable(_startDefense) : null,
        startBallNorm: _isAnimating ? _startBall : null,
        targetOffenseNorm: _isAnimating ? List.unmodifiable(_offense) : null,
        targetDefenseNorm: _isAnimating ? List.unmodifiable(_defense) : null,
        targetBallNorm: _isAnimating ? _ball : null,
      );
  
  int get ballOwnerSlot => _ballOwnerSlot;
  bool get isAnimating => _isAnimating;

  /// True while a queued session is in progress: currently interpolating a step
  /// **or** waiting to start the next step. Unlike [isAnimating] alone, this stays
  /// true during short gaps between steps (avoids UI that keys off [isAnimating] flickering).
  bool get isPlaybackSequenceActive => _isAnimating || _stepQueue.isNotEmpty;

  bool _isPaused = false;
  bool get isPaused => _isPaused;
  Duration _stepAnimationDuration = const Duration(milliseconds: 1200);

  double get animationProgress {
    if (!_isAnimating) return 0.0;
    final denom = _stepAnimationDuration.inMilliseconds;
    if (denom <= 0) return 1.0;
    return Curves.easeInOut.transform((_currentStepElapsed.inMilliseconds / denom).clamp(0.0, 1.0));
  }
  List<TimelineAction> get timeline => List.unmodifiable(_timeline);
  List<PlayStep> get recordedSteps => List.unmodifiable(_recordedSteps);

  void _onTick(Duration elapsed) {
    if (!_isAnimating || _isPaused) return;

    _currentStepElapsed = elapsed;
    final denomMs = _stepAnimationDuration.inMilliseconds;
    final rawT = denomMs <= 0 ? 1.0 : (_currentStepElapsed.inMilliseconds / denomMs).clamp(0.0, 1.0);
    final t = Curves.easeInOut.transform(rawT);
    
    for (int i = 0; i < 5; i++) {
      _curOffense[i] = Offset.lerp(_startOffense[i], _offense[i], t)!;
      _curDefense[i] = Offset.lerp(_startDefense[i], _defense[i], t)!;
    }
    _curBall = Offset.lerp(_startBall, _ball, t)!;

    if (rawT >= 1.0) {
      _ticker.stop();
      _isAnimating = false;
      notifyListeners(); // One last update for the 1.0 state

      final quickStep = _stepAnimationDuration.inMilliseconds < 280;
      final breatherMs = quickStep ? 28 : 250;
      if (!_disposed) {
        Future.delayed(Duration(milliseconds: breatherMs), () {
          if (!_disposed) _processNextStep();
        });
      }
      return;
    }
    notifyListeners();
  }

  Duration _currentStepElapsed = Duration.zero;

  void _startStepAnimation() {
    _startOffense = List<Offset>.from(_curOffense);
    _startDefense = List<Offset>.from(_curDefense);
    _startBall = _curBall;
    _currentStepElapsed = Duration.zero;
    _isAnimating = true;
    _isPaused = false;
    _ticker.start();
  }
  
  void pausePlayback() {
    if (_isAnimating && !_isPaused) {
      _isPaused = true;
      _ticker.stop();
      notifyListeners();
    }
  }

  void resumePlayback() {
    if (_isAnimating && _isPaused) {
      _isPaused = false;
      _ticker.start();
      notifyListeners();
    }
  }

  void applyParsedCommand(ParsedCoachCommand cmd) {
    if (cmd.steps.isNotEmpty) {
      // Record these steps into our session
      _recordedSteps.addAll(cmd.steps);
      
      // Start playback queue
      _stepQueue.addAll(cmd.steps);
      if (!_isAnimating) _processNextStep();
    }
  }

  /// Live drag: update offense (and ball if carrier) without appending a recorded step.
  void updateOffenseDragLive(int slot, Offset toNorm) {
    if (slot < 1 || slot > 5) return;
    _offense[slot - 1] = toNorm;
    if (_ballOwnerSlot == slot) _ball = toNorm;
    _curOffense[slot - 1] = toNorm;
    _curBall = _ball;
    notifyListeners();
  }

  /// Record a keyframe from drag / drop. Use [animationDurationMs] for snappy replay (defaults ~100ms).
  void recordManualMove(int slot, Offset toNorm, bool isOffense, {int? animationDurationMs}) {
    final ms = (animationDurationMs ?? 105).clamp(45, 400);
    final step = PlayStep(
      id: 'move_${_recordedSteps.length}',
      kind: PlayStepKind.cut,
      actorSlot: slot,
      toNorm: toNorm,
      animationDurationMs: ms,
    );
    _recordedSteps.add(step);
    
    // Instantly update target for immediate feedback during drag end
    if (isOffense && slot >= 1 && slot <= 5) {
      _offense[slot - 1] = toNorm;
      if (_ballOwnerSlot == slot) _ball = toNorm;
    }
    
    // We don't necessarily need to "animate" to where it just was dragged,
    // but we update the current state so it stays there.
    _curOffense = List<Offset>.from(_offense);
    _curBall = _ball;
    
    notifyListeners();
  }

  void playRecordedSession() {
    if (_isAnimating || _stepQueue.isNotEmpty || _recordedSteps.isEmpty) return;
    
    // Reset to initial formation before replaying
    _applyLayout(_formation);
    _curOffense = List<Offset>.from(_offense);
    _curDefense = List<Offset>.from(_defense);
    _curBall = _ball;
    
    _stepQueue.clear();
    _stepQueue.addAll(_recordedSteps);
    _processNextStep();
  }

  void _processNextStep() {
    if (_stepQueue.isEmpty) return;

    final step = _stepQueue.removeAt(0);
    final ms = (step.animationDurationMs ?? 1200).clamp(45, 12000);
    _stepAnimationDuration = Duration(milliseconds: ms);
    _applyStepLogic(step);
    _startStepAnimation();
  }

  void _applyStepLogic(PlayStep step) {
    // Current step reference for drawing paths
    _currentStep = step;

    // Helper to move a specific player
    void movePlayer(bool isDef, int slot, Offset toNorm) {
      final i = CourtSlots.slotToIndex(slot);
      if (isDef) {
        _defense[i] = toNorm;
      } else {
        _offense[i] = toNorm;
        if (_ballOwnerSlot == slot) _ball = toNorm;
      }
    }

    Offset getPlayerPos(bool isDef, int slot) {
      final i = CourtSlots.slotToIndex(slot);
      return isDef ? _defense[i] : _offense[i];
    }

    switch (step.kind) {
      case PlayStepKind.pass:
      case PlayStepKind.handoff:
        if (step.targetSlot != null) {
          final toPos = getPlayerPos(step.targetIsDefense, step.targetSlot!);
          _ball = toPos;
          _ballOwnerSlot = step.targetIsDefense ? -1 : step.targetSlot!; // If defense steals, we lose ball ownership for now
        }
        break;
      case PlayStepKind.cut:
      case PlayStepKind.flare:
      case PlayStepKind.roll:
      case PlayStepKind.pop:
      case PlayStepKind.drive:
      case PlayStepKind.screen:
      case PlayStepKind.staggerScreen:
        if (step.toNorm != null && step.actorSlot >= 1 && step.actorSlot <= 5) {
          movePlayer(step.isDefense, step.actorSlot, step.toNorm!);
        } else if (step.targetSlot != null && step.actorSlot >= 1 && step.actorSlot <= 5) {
          // Move NEAR target player (offset slightly so they don't overlap)
          final targetPos = getPlayerPos(step.targetIsDefense, step.targetSlot!);
          
          // If it's a screen, we move very close
          final offsetAmount = (step.kind == PlayStepKind.screen || step.kind == PlayStepKind.staggerScreen) ? 0.04 : 0.06;
          final offset = Offset(0, targetPos.dy > 0.5 ? -offsetAmount : offsetAmount); 
          final finalPos = targetPos + offset;
          
          movePlayer(step.isDefense, step.actorSlot, finalPos);
        }
        break;
      case PlayStepKind.shoot:
        // Animate ball to basket (center-top or center-bottom)
        // For now, always North basket (top end in vertical, left in horizontal)
        _ball = const Offset(0.5, 0.05);
        _ballOwnerSlot = -1; // Ball is in flight
        break;
      default:
        break;
    }
    _pushTimeline(step.kind, {'actor': step.actorSlot});
  }

  void _applyLayout(FormationPreset f) {
    final layout = CourtSlots.fullCourt(f);
    _offense = List<Offset>.from(layout.offense);
    _defense = List<Offset>.from(layout.defense);
    _ball = _offense[CourtSlots.slotToIndex(_ballOwnerSlot.clamp(1, 5))];
  }

  void _pushTimeline(PlayStepKind kind, Map<String, dynamic> data) {
    _timeline.add(TimelineAction(
      id: 't_${_timeline.length}',
      at: Duration(milliseconds: 800 * _timeline.length),
      source: 'engine',
      kind: kind,
      data: data,
    ));
  }

  PlayStep? _currentStep;
  PlayStep? get currentStep => _currentStep;

  void reset() {
    _ticker.stop();
    _isAnimating = false;
    _isPaused = false;
    _currentStepElapsed = Duration.zero;
    _currentStep = null;
    _stepQueue.clear();
    _recordedSteps.clear(); // Important: clear the session too
    _formation = FormationPreset.man23;
    _ballOwnerSlot = 1;
    final layout = CourtSlots.fullCourt(_formation);
    _offense = List<Offset>.from(layout.offense);
    _defense = List<Offset>.from(layout.defense);
    _ball = _offense[CourtSlots.slotToIndex(1)];
    
    _curOffense = List<Offset>.from(_offense);
    _curDefense = List<Offset>.from(_defense);
    _curBall = _ball;
    
    _timeline.clear();
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    super.dispose();
  }
}
