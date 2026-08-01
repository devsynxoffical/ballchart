import 'dart:async' show unawaited;
import 'dart:math' show sin, pi;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:ballchart/core/utils/app_messenger.dart';
import 'package:flutter/services.dart' show MissingPluginException, HapticFeedback;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/voice_note_service.dart';
import '../../../core/services/whisper_transcription_service.dart';
import '../../../core/utils/mic_permission.dart';
import '../../../core/models/tactical/tactical_voice_clip.dart';
import '../../../core/widgets/tactics/coach_voice_clips_panel.dart';
import '../../../core/tactical/coach_speech_normalizer.dart';
import '../../../core/tactical/court_geometry.dart';
import '../../../core/tactical/tactical_ai_suggestions.dart';
import '../../../core/tactical/tactical_animation_engine.dart';
import '../../../core/tactical/tactical_court_canvas.dart';
import '../../../core/tactical/voice_command_parser.dart';
import '../../../core/models/tactical/tactical_schema.dart';
import '../../../core/tactical/tactical_entities.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../../management/viewmodel/academy_provider.dart';
import '../../strategy/viewmodel/strategy_viewmodel.dart';

class TacticalLabScreen extends StatefulWidget {
  final String? battleId;
  final bool initialPlayerMode;
  final List<PlayStep>? initialSteps;
  final List<Map<String, dynamic>>? initialVoiceClips;
  final bool returnOnSave;

  const TacticalLabScreen({
    super.key, 
    this.battleId, 
    this.initialPlayerMode = false,
    this.initialSteps,
    this.initialVoiceClips,
    this.returnOnSave = false,
  });

  @override
  State<TacticalLabScreen> createState() => _TacticalLabScreenState();
}

class _TacticalLabScreenState extends State<TacticalLabScreen> with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _commandFocus = FocusNode();
  final _playback = TacticalPlaybackController();
  final _whisper = WhisperTranscriptionService();
  bool _whisperReady = false;
  bool _listening = false;
  /// True after user taps mic until they stop or tap RECORD FLOW.
  bool _voiceSessionActive = false;
  /// True after user taps mic until the platform reports listening (covers connect latency).
  bool _voiceSessionPending = false;
  bool _voiceFileRecordingStarted = false;
  /// True while Whisper is converting the finished recording into text.
  bool _isTranscribing = false;
  int _transcribeProgress = 0;
  String? _micHint;
  final _api = ApiService();
  final _voiceNoteSvc = VoiceNoteService();
  final List<TacticalVoiceRecording> _sessionVoiceRecordings = [];
  List<TacticalVoiceClip> _playbackVoiceClips = [];

  bool get _voiceUiActive => _voiceSessionActive || _voiceSessionPending;

  int? _draggingSlot;
  /// Freehand finger drawing on the court (coach mode).
  bool _drawMode = false;
  /// When true, one-finger pans/zooms the court. When false (default),
  /// one-finger drags players.
  bool _courtNavigateMode = false;
  final GlobalKey _courtKey = GlobalKey();
  final List<List<Offset>> _drawStrokes = [];
  List<Offset>? _activeStroke;
  /// Throttle drag → recorded keyframes (keep dense for smooth replay).
  DateTime? _lastDragKeyframeAt;
  Offset? _lastDragKeyframeNorm;
  Offset? _dragPointerStartNorm;
  static const Duration _dragKeyframeMinInterval = Duration(milliseconds: 16);
  static const double _dragKeyframeMinDistance = 0.006;
  final _saveNameCtrl = TextEditingController();
  final _coachTipsCtrl = TextEditingController();
  String? _selectedTeamId;
  String? _selectedPlayerId;
  bool _isSaving = false;
  bool _isParsingCommand = false;
  
  // Mock Playbook Library
  final List<Map<String, dynamic>> _savedPlaybooks = [
    {
      'name': 'Horns Clear-out',
      'steps': [
        const PlayStep(id: '1', kind: PlayStepKind.cut, actorSlot: 5, targetSlot: 1),
        const PlayStep(id: '2', kind: PlayStepKind.pass, actorSlot: 1, targetSlot: 2),
        const PlayStep(id: '3', kind: PlayStepKind.shoot, actorSlot: 2),
      ]
    },
    {
      'name': 'Fast Break Lane Fill',
      'steps': [
        const PlayStep(id: '1', kind: PlayStepKind.pass, actorSlot: 1, targetSlot: 3),
        const PlayStep(id: '2', kind: PlayStepKind.cut, actorSlot: 3, toNorm: Offset(0.5, 0.88)),
        const PlayStep(id: '3', kind: PlayStepKind.shoot, actorSlot: 3),
      ]
    },
    {
      'name': 'Horns Pick & Roll',
      'steps': [
        const PlayStep(id: '1', kind: PlayStepKind.screen, actorSlot: 5, targetSlot: 1),
        const PlayStep(id: '2', kind: PlayStepKind.roll, actorSlot: 5, toNorm: Offset(0.5, 0.82)),
        const PlayStep(id: '3', kind: PlayStepKind.pass, actorSlot: 1, targetSlot: 5),
      ]
    },
    {
      'name': 'Zone Overload Skip',
      'steps': [
        const PlayStep(id: '1', kind: PlayStepKind.cut, actorSlot: 2, toNorm: Offset(0.88, 0.72)),
        const PlayStep(id: '2', kind: PlayStepKind.pass, actorSlot: 1, targetSlot: 2),
        const PlayStep(id: '3', kind: PlayStepKind.shoot, actorSlot: 2),
      ]
    },
  ];
  bool _isPlayerMode = false;
  Map<String, dynamic>? _activePlaybook;
  bool _hasInjectedPlayback = false;

  /// Drives chrome that should not rebuild every animation tick — only when
  /// [TacticalPlaybackController.isPlaybackSequenceActive] flips.
  final ValueNotifier<bool> _playbackSequenceActiveUi = ValueNotifier<bool>(false);

  late final AnimationController _micPulseCtrl;

  static const Color _primary = Color(0xFFFFD900);
  static const Color _bg = Color(0xFF131313);
  static const Color _surface = Color(0xFF201F1F);
  static const Color _outline = Color(0xFF9D8F79);

  bool get _isViewingSavedPlayback => _isPlayerMode && _activePlaybook != null;

  void _syncPlaybackSequenceUi() {
    final active = _playback.isPlaybackSequenceActive;
    if (_playbackSequenceActiveUi.value != active) {
      _playbackSequenceActiveUi.value = active;
    }
  }

  List<Map<String, dynamic>> _teamOptions(AcademyProvider academy) {
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    final dashboardTeams = academy.coachDashboard?['teams'] as List<dynamic>? ?? const [];
    for (final t in dashboardTeams) {
      if (t is! Map) continue;
      final map = Map<String, dynamic>.from(t);
      final id = (map['_id'] ?? map['id'] ?? '').toString();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      out.add(map);
    }

    for (final t in academy.academy.teams) {
      if (seen.contains(t.id)) continue;
      seen.add(t.id);
      out.add({
        '_id': t.id,
        'name': t.name,
        'players': t.players
            .map((p) => {
                  '_id': p.id,
                  'username': p.name,
                })
            .toList(),
      });
    }

    return out;
  }

  @override
  void initState() {
    super.initState();
    _micPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _playback.addListener(_syncPlaybackSequenceUi);
    _isPlayerMode = widget.initialPlayerMode;
    
    if (widget.initialSteps != null && widget.initialSteps!.isNotEmpty) {
      _hasInjectedPlayback = true;
      _activePlaybook = {
        'name': 'Imported Strategy',
        'steps': widget.initialSteps!,
      };
      _playback.applyParsedCommand(ParsedCoachCommand(
        intent: CoachIntent.sequence,
        steps: widget.initialSteps!,
      ));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _playback.playRecordedSession();
      });
    }

    if (widget.initialVoiceClips != null && widget.initialVoiceClips!.isNotEmpty) {
      _playbackVoiceClips = widget.initialVoiceClips!
          .map((e) => TacticalVoiceClip.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.canPlay || c.transcript.isNotEmpty)
          .toList();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPlaybackSequenceUi();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final role = (context.read<ProfileViewmodel>().user?.role ?? '').toLowerCase();
      if (role == 'player' && !_isPlayerMode) {
        setState(() => _isPlayerMode = true);
      }
      _setupSpeech();
      _api.connectSocket();
    });
  }

  void _setupSpeech() {
    if (kIsWeb || _isPlayerMode) return;
    setState(() {
      _whisperReady = true;
      _micHint = null;
    });
  }

  /// Makes sure the Whisper model is on the device, showing a progress
  /// dialog for the one-time ~142 MB download. Returns true when ready.
  Future<bool> _ensureWhisperModel() async {
    try {
      if (await _whisper.isModelReady()) return true;
    } catch (_) {}
    if (!mounted) return false;

    final progress = ValueNotifier<double>(0);
    final receivedMb = ValueNotifier<double>(0);
    var cancelled = false;

    final download = _whisper.downloadModel(
      onProgress: (p, bytes) {
        progress.value = p;
        receivedMb.value = bytes / (1024 * 1024);
      },
      isCancelled: () => cancelled,
    );

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        download.then((_) {
          if (ctx.mounted) Navigator.pop(ctx, true);
        }).catchError((Object e) {
          if (ctx.mounted) Navigator.pop(ctx, false);
          if (mounted && e is! WhisperDownloadCancelled) {
            setState(() => _micHint = 'Voice model download failed: $e');
          }
        });
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: _surface,
            title: const Text('Preparing voice recognition',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Downloading the offline speech model (one time, ~142 MB). '
                  'After this, voice commands work without internet.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (_, p, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: p >= 0 ? p : null,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<double>(
                  valueListenable: receivedMb,
                  builder: (_, mb, __) => ValueListenableBuilder<double>(
                    valueListenable: progress,
                    builder: (_, p, __) => Text(
                      p >= 0
                          ? '${(p * 100).toStringAsFixed(0)}% — ${mb.toStringAsFixed(1)} MB downloaded'
                          : '${mb.toStringAsFixed(1)} MB downloaded',
                      style: const TextStyle(color: _outline, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cancelled = true;
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        );
      },
    );

    progress.dispose();
    receivedMb.dispose();

    if (ok != true && mounted && cancelled) {
      setState(() => _micHint =
          'Voice model download cancelled. Tap the mic again to resume.');
    }
    return ok == true;
  }

  Future<void> _maybeStartFileRecording() async {
    if (_voiceFileRecordingStarted || !_voiceSessionActive) return;
    _voiceFileRecordingStarted = true;
    try {
      // WAV @16 kHz mono: Whisper reads it natively, no conversion needed.
      await _voiceNoteSvc.startRecording(forTranscription: true);
    } catch (_) {
      // Let _toggleVoiceCommand's error handler surface the failure instead
      // of pulsing a fake "recording" state that captures nothing.
      _voiceFileRecordingStarted = false;
      rethrow;
    }
  }

  Future<void> _showMicSettingsDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Microphone access needed', style: TextStyle(color: Colors.white)),
        content: const Text(
          'BallChart needs microphone and speech recognition access for voice commands. '
          'Open Settings and enable both permissions for BallChart.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  List<TacticalVoiceClip> get _displayVoiceClips {
    if (_sessionVoiceRecordings.isNotEmpty) {
      return _sessionVoiceRecordings.map((r) => r.toClip()).toList();
    }
    return _playbackVoiceClips;
  }

  String get _combinedVoiceTranscript {
    final fromClips = _sessionVoiceRecordings
        .map((r) => r.transcript.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (fromClips.isNotEmpty) return fromClips.join(' → ');
    return _textCtrl.text.trim();
  }

  Future<void> _commitActiveVoiceClip({String? transcriptOverride}) async {
    final clip = await _voiceNoteSvc.stopRecording();
    if (!mounted) return;

    var transcript = transcriptOverride?.trim() ?? '';
    String? transcribeError;
    if (clip != null && transcript.isEmpty) {
      setState(() {
        _isTranscribing = true;
        _transcribeProgress = 0;
      });
      try {
        transcript = await _whisper.transcribe(
          clip.localPath,
          onProgress: (percent) {
            if (mounted) {
              setState(() => _transcribeProgress = percent);
            }
          },
        );
      } catch (e) {
        transcribeError = e.toString().replaceFirst('Exception: ', '');
        if (kDebugMode) print('Whisper transcription failed: $e');
      }
      if (mounted) {
        setState(() => _isTranscribing = false);
      }
    }

    if (!mounted) return;
    if (transcript.isNotEmpty) {
      final existing = _textCtrl.text.trim();
      final combined = existing.isEmpty ? transcript : '$existing, then $transcript';
      _textCtrl.value = TextEditingValue(
        text: combined,
        selection: TextSelection.collapsed(offset: combined.length),
      );
    } else if (clip != null) {
      setState(() {
        _micHint = transcribeError != null
            ? 'Voice-to-text failed: $transcribeError — your audio is still saved below.'
            : 'No speech detected — speak louder and closer to the phone, then try again.';
      });
    } else {
      setState(() {
        _micHint = 'Nothing was recorded — hold the phone closer and tap the mic to try again.';
      });
    }

    if (clip != null &&
        (clip.duration.inMilliseconds >= 250 || transcript.isNotEmpty)) {
      setState(() {
        _sessionVoiceRecordings.add(
          TacticalVoiceRecording(
            localPath: clip.localPath,
            duration: clip.duration,
            transcript: transcript,
          ),
        );
      });
      return;
    }

    if (transcript.isNotEmpty) {
      setState(() {
        _sessionVoiceRecordings.add(
          TacticalVoiceRecording(
            duration: Duration.zero,
            transcript: transcript,
          ),
        );
      });
    }
  }

  Future<void> _finalizeVoiceSession() async {
    if (!_voiceSessionActive && !_voiceSessionPending && !_listening) {
      return;
    }

    // Flip the UI out of "recording" immediately so the user sees the
    // session ended; transcription state is shown separately.
    _micPulseCtrl.stop();
    _micPulseCtrl.value = 0;
    if (mounted) {
      setState(() {
        _listening = false;
        _voiceSessionActive = false;
        _voiceSessionPending = false;
        _voiceFileRecordingStarted = false;
        _micHint = null;
      });
    }

    final hadTextBefore = _textCtrl.text.trim();
    await _commitActiveVoiceClip();
    if (mounted) {
      setState(() {
        final gotNewText = _textCtrl.text.trim() != hadTextBefore &&
            _textCtrl.text.trim().isNotEmpty;
        if (gotNewText) {
          _micHint =
              'Your words are in the box above — tap RECORD FLOW to animate them.';
        } else if (_micHint == null || _micHint!.isEmpty) {
          _micHint = _sessionVoiceRecordings.isNotEmpty
              ? '${_sessionVoiceRecordings.length} voice command(s) saved — will attach when you save the tactic.'
              : 'Voice capture stopped. Tap mic to record again, or tap RECORD FLOW to run your text.';
        }
      });
    }
  }

  Future<void> _toggleVoiceCommand() async {
    if (_isPlayerMode) return;

    if (_voiceUiActive) {
      await _finalizeVoiceSession();
      return;
    }

    if (!_whisperReady) {
      if (mounted) {
        setState(() => _micHint = 'Local Whisper is unavailable on this device.');
      }
      return;
    }

    if (!kIsWeb) {
      final permission = await ensureVoicePermissions();
      if (!permission.granted) {
        if (mounted) {
          setState(() => _micHint = permission.message);
          if (permission.openSettings) {
            _showMicSettingsDialog();
          }
        }
        return;
      }
    }

    // One-time model download with visible progress before first recording.
    if (!await _ensureWhisperModel()) return;
    if (!mounted) return;

    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        _voiceSessionActive = true;
        _voiceSessionPending = true;
        _voiceFileRecordingStarted = false;
        _micHint = null;
      });
      FocusScope.of(context).requestFocus(_commandFocus);
    }

    try {
      await _maybeStartFileRecording();
      if (mounted) {
        setState(() {
          _voiceSessionPending = false;
          _listening = true;
        });
        _micPulseCtrl.repeat(reverse: true);
      }
    } on MissingPluginException {
      await _voiceNoteSvc.cancelRecording();
      _micPulseCtrl.stop();
      if (mounted) {
        setState(() {
          _voiceSessionActive = false;
          _voiceSessionPending = false;
          _listening = false;
          _voiceFileRecordingStarted = false;
          _micHint = 'Audio recording plugin missing on this build.';
        });
      }
    } catch (e) {
      await _voiceNoteSvc.cancelRecording();
      _micPulseCtrl.stop();
      if (mounted) {
        setState(() {
          _voiceSessionActive = false;
          _voiceSessionPending = false;
          _listening = false;
          _voiceFileRecordingStarted = false;
          _micHint = 'Voice capture failed: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _playback.removeListener(_syncPlaybackSequenceUi);
    _playbackSequenceActiveUi.dispose();
    _micPulseCtrl.dispose();
    _commandFocus.dispose();
    unawaited(_voiceNoteSvc.cancelRecording());
    _voiceNoteSvc.dispose();
    _textCtrl.dispose();
    _saveNameCtrl.dispose();
    _coachTipsCtrl.dispose();
    _playback.dispose();
    super.dispose();
  }

  Future<void> _runCommand(String raw) async {
    if (_isPlayerMode || raw.trim().isEmpty) return;

    final normalized = normalizeCoachSpeech(raw);
    if (normalized.isEmpty) return;

    setState(() {
      _isParsingCommand = true;
    });

    ParsedCoachCommand parsed = parseCoachCommand(normalized);
    bool usedAi = false;

    try {
      // The backend AI sees the complete natural sentence and converts it to
      // the small, validated PlayStep schema used by the animation engine.
      final res = await _api.parseVoiceCommand(raw.trim());
      final aiParsed = ParsedCoachCommand.fromJson(res, raw.trim());
      if (aiParsed.intent != CoachIntent.unknown && aiParsed.steps.isNotEmpty) {
        parsed = aiParsed;
        usedAi = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI voice parse unavailable, using local parser: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _isParsingCommand = false;
    });

    if (parsed.confidence >= 0.5 && parsed.intent != CoachIntent.unknown) {
      _playback.applyParsedCommand(parsed);
      // Command consumed — clear the bar so it is ready for the next one.
      // On failure the text stays so the coach can edit and retry.
      _textCtrl.clear();
      setState(() => _micHint = null);
      final stepCount = parsed.steps.length;
      final label = stepCount > 1 ? 'Sequence: $stepCount steps' : 'Command: ${parsed.intent.name.toUpperCase()}';
      final modeLabel = usedAi ? 'AI' : 'Local';

      AppMessenger.showSnackBar(context, 
        SnackBar(
          content: Text('Recognized ($modeLabel): $label', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: _primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        )
      );
    } else if (normalized.isNotEmpty) {
      AppMessenger.showSnackBar(context, 
        SnackBar(
          content: Text(
            'Try: "Player one pass player two" or "P1 shoot"\nHeard: $normalized',
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Offset? _courtLocalFromGlobal(Offset global) {
    final box = _courtKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.globalToLocal(global);
  }

  void _beginPlayerDrag(int slot) {
    if (_isPlayerMode || _playback.isPlaybackSequenceActive) return;
    final startNorm = _playback.frame.offenseNorm[slot - 1];
    setState(() {
      _draggingSlot = slot;
      _dragPointerStartNorm = startNorm;
      _lastDragKeyframeAt = null;
      _lastDragKeyframeNorm = null;
    });
    _playback.updateOffenseDragLive(slot, startNorm);
  }

  void _dragPlayerToGlobal(Offset global, double w, double h) {
    final slot = _draggingSlot;
    if (slot == null) return;
    final local = _courtLocalFromGlobal(global);
    if (local == null) return;
    final norm = CourtSlots.pixelToNorm(local, Size(w, h));
    _playback.updateOffenseDragLive(slot, norm);
    _maybeRecordDragKeyframe(slot, norm, force: false);
  }

  void _onDrawPointerDown(PointerDownEvent event, double w, double h) {
    if (!_drawMode || _isPlayerMode || _playback.isPlaybackSequenceActive) return;
    final local = event.localPosition;
    final norm = CourtSlots.pixelToNorm(local, Size(w, h));
    setState(() {
      _activeStroke = [norm];
      _drawStrokes.add(_activeStroke!);
    });
  }

  void _onDrawPointerMove(PointerMoveEvent event, double w, double h) {
    if (!_drawMode) return;
    final stroke = _activeStroke;
    if (stroke == null) return;
    final norm = CourtSlots.pixelToNorm(event.localPosition, Size(w, h));
    if (stroke.isEmpty || (stroke.last - norm).distance > 0.003) {
      setState(() => stroke.add(norm));
    }
  }

  int _dragKeyframeDurationMs(Offset? prev, Offset norm) {
    if (prev == null) return 55;
    final d = (norm - prev).distance;
    return (28 + d * 480).round().clamp(28, 110);
  }

  void _maybeRecordDragKeyframe(int slot, Offset norm, {required bool force}) {
    final now = DateTime.now();
    final prevNorm = _lastDragKeyframeNorm;
    final lastAt = _lastDragKeyframeAt;

    if (!force) {
      if (lastAt != null && now.difference(lastAt) < _dragKeyframeMinInterval) {
        return;
      }
      if (prevNorm != null && (norm - prevNorm).distance < _dragKeyframeMinDistance) {
        return;
      }
    } else {
      if (prevNorm != null && (norm - prevNorm).distance < 0.003) return;
    }

    _lastDragKeyframeAt = now;
    _lastDragKeyframeNorm = norm;
    _playback.recordManualMove(
      slot,
      norm,
      true,
      animationDurationMs: _dragKeyframeDurationMs(prevNorm, norm),
    );
  }

  void _endPointerInteraction() {
    if (_drawMode) {
      setState(() => _activeStroke = null);
      return;
    }
    if (_draggingSlot != null) {
      final slot = _draggingSlot!;
      final cur = _playback.frame.offenseNorm[slot - 1];
      final started = _dragPointerStartNorm;
      if (started != null && (cur - started).distance > 0.005) {
        _maybeRecordDragKeyframe(slot, cur, force: true);
      }
      setState(() {
        _draggingSlot = null;
        _dragPointerStartNorm = null;
        _lastDragKeyframeAt = null;
        _lastDragKeyframeNorm = null;
      });
    }
  }

  List<Widget> _buildOffenseDragHandles(double w, double h) {
    final size = Size(w, h);
    const handle = 64.0;
    final handles = <Widget>[];
    for (int i = 0; i < 5; i++) {
      final slot = i + 1;
      final pixel = CourtSlots.normToPixel(_playback.frame.offenseNorm[i], size);
      final selected = _draggingSlot == slot;
      handles.add(
        Positioned(
          left: pixel.dx - handle / 2,
          top: pixel.dy - handle / 2,
          width: handle,
          height: handle,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => _beginPlayerDrag(slot),
            onPanUpdate: (d) => _dragPlayerToGlobal(d.globalPosition, w, h),
            onPanEnd: (_) => _endPointerInteraction(),
            onPanCancel: _endPointerInteraction,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _primary.withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: selected ? _primary : Colors.white.withValues(alpha: 0.45),
                  width: selected ? 2.5 : 1.4,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return handles;
  }

  Future<void> _savePlaybook() async {
    if (_playback.recordedSteps.isEmpty) {
      AppMessenger.showSnackBar(context, const SnackBar(content: Text('No actions recorded to save.')));
      return;
    }

    await _finalizeVoiceSession();
    if (!mounted) return;

    final academy = context.read<AcademyProvider>();
    final strategyVm = context.read<StrategyViewmodel>();
    
    // Ensure coach dashboard data is available for team/player assignment.
    if (academy.coachDashboard == null) {
      await academy.loadCoachDashboard(force: true);
      if (!mounted) return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final teams = _teamOptions(academy);
          final selectedTeam = teams.isNotEmpty
              ? teams.firstWhere(
                  (t) => (t['_id'] ?? t['id'] ?? '').toString() == _selectedTeamId,
                  orElse: () => teams.first,
                )
              : null;
          
          if (_selectedTeamId == null && teams.isNotEmpty) {
            _selectedTeamId = (teams.first['_id'] ?? teams.first['id']).toString();
          }
          final players = selectedTeam == null
              ? const <dynamic>[]
              : (selectedTeam['players'] as List<dynamic>? ?? const <dynamic>[]);

          if (_selectedPlayerId != null) {
            final stillExists = players.any(
              (p) => p is Map && (p['_id'] ?? p['id'] ?? '').toString() == _selectedPlayerId,
            );
            if (!stillExists) {
              _selectedPlayerId = null;
            }
          }

          return AlertDialog(
            backgroundColor: _surface,
            title: const Text('Save & Assign Flow', style: TextStyle(color: Colors.white, fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TACTIC NAME', style: TextStyle(color: _outline, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _saveNameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. Horns Red Pick & Roll',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text('ASSIGN TO TEAM (OPTIONAL)', style: TextStyle(color: _outline, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTeamId,
                        dropdownColor: _surface,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        hint: const Text('Select Team', style: TextStyle(color: Colors.white24)),
                        items: teams
                            .map(
                              (t) => DropdownMenuItem<String>(
                                value: (t['_id'] ?? t['id'] ?? '').toString(),
                                child: Text((t['name'] ?? 'Team').toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            _selectedTeamId = val;
                            _selectedPlayerId = null; // Reset player when team changes
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('ASSIGN TO PLAYER (OPTIONAL)', style: TextStyle(color: _outline, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedPlayerId,
                        dropdownColor: _surface,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        hint: const Text('All Players', style: TextStyle(color: Colors.white24)),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All Players')),
                          ...players
                              .whereType<Map>()
                              .map(
                                (p) => DropdownMenuItem<String?>(
                                  value: (p['_id'] ?? p['id'] ?? '').toString(),
                                  child: Text((p['username'] ?? p['name'] ?? 'Player').toString()),
                                ),
                              ),
                        ],
                        onChanged: (val) {
                          setDialogState(() => _selectedPlayerId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('COACH TIPS / NOTES', style: TextStyle(color: _outline, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _coachTipsCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add instructions for the players...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('CANCEL', style: TextStyle(color: _outline, fontWeight: FontWeight.bold))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, 
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _isSaving ? null : () async {
                  if (_saveNameCtrl.text.isEmpty) {
                    AppMessenger.showSnackBar(context, const SnackBar(content: Text('Please enter a name for the tactic.')));
                    return;
                  }

                  setDialogState(() => _isSaving = true);

                  try {
                    String? selectedPlayerName;
                    if (_selectedPlayerId != null && selectedTeam != null) {
                      for (final p in players) {
                        if (p is! Map) continue;
                        final id = (p['_id'] ?? p['id'] ?? '').toString();
                        if (id == _selectedPlayerId) {
                          selectedPlayerName = (p['username'] ?? p['name'] ?? '').toString();
                          break;
                        }
                      }
                    }

                    final transcript = _combinedVoiceTranscript;
                    final voiceClipsMeta = <Map<String, dynamic>>[];
                    String? primaryVoiceUrl;
                    int? primaryVoiceDurationMs;
                    var uploadFailures = 0;
                    for (final recording in _sessionVoiceRecordings) {
                      String? uploadedUrl;
                      if (recording.localPath.isNotEmpty) {
                        try {
                          uploadedUrl = await _voiceNoteSvc.uploadClip(
                            VoiceClip(localPath: recording.localPath, duration: recording.duration),
                          );
                        } catch (_) {
                          uploadFailures++;
                        }
                      }
                      final entry = <String, dynamic>{
                        'durationMs': recording.duration.inMilliseconds,
                        'transcript': recording.transcript,
                        'recordedAt': recording.recordedAt.toIso8601String(),
                        if (recording.localPath.isNotEmpty) 'localPath': recording.localPath,
                      };
                      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                        entry['url'] = uploadedUrl;
                        primaryVoiceUrl ??= uploadedUrl;
                        primaryVoiceDurationMs ??= recording.duration.inMilliseconds;
                      } else if (recording.localPath.isNotEmpty) {
                        entry['uploadPending'] = true;
                      }
                      voiceClipsMeta.add(entry);
                    }

                    final metadata = <String, dynamic>{
                      'playSteps': _playback.recordedSteps.map((s) => s.toJson()).toList(),
                      'coachTips': _coachTipsCtrl.text,
                      'assignedTeamId': _selectedTeamId,
                      'assignedPlayerId': _selectedPlayerId,
                      'assignedPlayerName': selectedPlayerName,
                      'recordedAt': DateTime.now().toIso8601String(),
                    };
                    if (transcript.isNotEmpty) metadata['voiceTranscript'] = transcript;
                    if (primaryVoiceUrl != null) metadata['voiceUrl'] = primaryVoiceUrl;
                    if (primaryVoiceDurationMs != null) {
                      metadata['voiceDurationMs'] = primaryVoiceDurationMs;
                    }
                    if (voiceClipsMeta.isNotEmpty) metadata['voiceClips'] = voiceClipsMeta;

                    await strategyVm.createStrategy(
                      title: _saveNameCtrl.text,
                      category: 'offense',
                      sourceType: voiceClipsMeta.isNotEmpty ? 'voice' : 'text',
                      sourceText: transcript.isNotEmpty
                          ? transcript
                          : 'Recorded tactical flow from Tactical Lab',
                      isPublic: true,
                      metadata: metadata,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      final msg = uploadFailures > 0
                          ? 'Tactic saved. Voice text + plays saved; $uploadFailures clip(s) waiting on audio upload.'
                          : 'Tactic saved with coach voice — players can replay it from Strategy.';
                      AppMessenger.showSnackBar(context, 
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: uploadFailures > 0 ? Colors.orange : Colors.green,
                        ),
                      );
                      setState(() {
                        _savedPlaybooks.insert(0, {
                          'name': _saveNameCtrl.text,
                          'steps': List<PlayStep>.from(_playback.recordedSteps),
                          'coachTips': _coachTipsCtrl.text,
                          'voiceClips': voiceClipsMeta,
                          'voiceTranscript': transcript,
                        });
                        _playbackVoiceClips = voiceClipsMeta
                            .map((e) => TacticalVoiceClip.fromJson(Map<String, dynamic>.from(e)))
                            .toList();
                        _saveNameCtrl.clear();
                        _coachTipsCtrl.clear();
                        _sessionVoiceRecordings.clear();
                      });
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppMessenger.showSnackBar(context, 
                        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent)
                      );
                    }
                  } finally {
                    setDialogState(() => _isSaving = false);
                  }
                },
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('SAVE & PUBLISH', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          );
        }
      ),
    );
  }


  void _loadPlaybook(Map<String, dynamic> pb) {
    final rawClips = pb['voiceClips'];
    final clips = rawClips is List
        ? rawClips
            .whereType<Map>()
            .map((e) => TacticalVoiceClip.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <TacticalVoiceClip>[];
    setState(() {
      _activePlaybook = pb;
      _playbackVoiceClips = clips;
      _sessionVoiceRecordings.clear();
    });
    _playback.reset();
    _playback.applyParsedCommand(ParsedCoachCommand(
      intent: CoachIntent.sequence,
      steps: pb['steps'] as List<PlayStep>,
    ));
    _playback.playRecordedSession();
  }

  Widget _buildVoiceSessionBanner() {
    final active = _listening;
    return AnimatedBuilder(
      animation: _micPulseCtrl,
      builder: (context, _) {
        final wave = _micPulseCtrl.isAnimating ? 0.5 + 0.5 * sin(_micPulseCtrl.value * pi) : 0.85;
        final borderA = (0.45 + 0.45 * wave).clamp(0.0, 1.0);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.08 + 0.08 * wave),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _primary.withValues(alpha: borderA), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.graphic_eq_rounded, color: _primary.withValues(alpha: 0.85 + 0.15 * wave), size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? Colors.redAccent.withValues(alpha: 0.6 + 0.4 * wave)
                                : _outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          active ? 'RECORDING — PLEASE SPEAK NOW' : 'GET READY…',
                          style: TextStyle(
                            color: _primary.withValues(alpha: 0.98),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      active
                          ? 'Say your play, e.g. "Player one pass to player two, player two shoot". '
                              'Tap the mic again when you finish — your words will appear in the box above.'
                          : 'Opening the microphone — start speaking when you see RECORDING.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = (context.watch<ProfileViewmodel>().user?.role ?? '').toLowerCase();
    final isPlayerRole = role == 'player';
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isPlayerMode ? 'PLAYBOOK LIBRARY' : 'TACTICAL LAB',
              style: const TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
            ),
            if (!_isPlayerMode)
              const Text(
                'Basketball court · 5v5',
                style: TextStyle(color: _outline, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
          ],
        ),
        actions: [
          if (!_isPlayerMode) ...[
            IconButton(
              onPressed: () => setState(() {
                _courtNavigateMode = !_courtNavigateMode;
                if (_courtNavigateMode) {
                  _drawMode = false;
                  _draggingSlot = null;
                  _activeStroke = null;
                }
              }),
              icon: Icon(
                _courtNavigateMode ? Icons.pan_tool_alt : Icons.pan_tool_alt_outlined,
                color: _courtNavigateMode ? _primary : Colors.white70,
              ),
              tooltip: _courtNavigateMode ? 'Exit pan/zoom' : 'Pan & zoom court',
            ),
            IconButton(
              onPressed: () => setState(() {
                _drawMode = !_drawMode;
                _draggingSlot = null;
                _activeStroke = null;
                if (_drawMode) _courtNavigateMode = false;
              }),
              icon: Icon(
                _drawMode ? Icons.edit : Icons.edit_outlined,
                color: _drawMode ? _primary : Colors.white70,
              ),
              tooltip: _drawMode ? 'Exit draw mode' : 'Finger draw on court',
            ),
            if (_drawStrokes.isNotEmpty)
              IconButton(
                onPressed: () => setState(() {
                  _drawStrokes.clear();
                  _activeStroke = null;
                }),
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
                tooltip: 'Clear drawings',
              ),
          ],
          if (widget.returnOnSave)
            TextButton.icon(
              onPressed: () => Navigator.pop(context, _playback.recordedSteps),
              icon: const Icon(Icons.check_circle, color: _primary),
              label: const Text('IMPORT TO PLAY', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
            )
          else ...[
            if (!isPlayerRole && !_isPlayerMode)
              IconButton(onPressed: _savePlaybook, icon: const Icon(Icons.share_outlined, color: _primary)),
            if (!isPlayerRole)
              IconButton(
                onPressed: () => setState(() {
                  _isPlayerMode = !_isPlayerMode;
                  _activePlaybook = null;
                  _drawMode = false;
                  _courtNavigateMode = false;
                }),
                icon: Icon(_isPlayerMode ? Icons.admin_panel_settings_outlined : Icons.person_search_outlined, color: _primary),
                tooltip: _isPlayerMode ? 'Switch to Coach' : 'Switch to Player',
              ),
          ],
        ],
      ),
      body: _isPlayerMode && _activePlaybook == null && !_hasInjectedPlayback
          ? _buildPlayerLibraryView()
          : _buildMainTacticalView(),
    );
  }

  Widget _buildPlayerLibraryView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _savedPlaybooks.length,
      itemBuilder: (context, i) {
        final pb = _savedPlaybooks[i];
        final stepCount = (pb['steps'] as List).length;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary.withValues(alpha: 0.22)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_primary, _primary.withValues(alpha: 0.78)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.sports_basketball, color: Colors.black, size: 22),
            ),
            title: Text(
              pb['name'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primary.withValues(alpha: 0.35)),
                    ),
                    child: const Text(
                      'SAVED TACTIC',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$stepCount steps',
                    style: const TextStyle(color: _outline, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: _primary, size: 22),
            ),
            onTap: () => _loadPlaybook(pb),
          ),
        );
      },
    );
  }

  Widget _buildMainTacticalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activePlaybook != null) 
            Row(
              children: [
                IconButton(onPressed: () => setState(() => _activePlaybook = null), icon: const Icon(Icons.arrow_back, color: _primary)),
                Text('Viewing: ${_activePlaybook!['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          
          ValueListenableBuilder<bool>(
            valueListenable: _playbackSequenceActiveUi,
            builder: (context, seqActive, _) {
              if (seqActive) return const SizedBox.shrink();
              return Text(
                _isPlayerMode
                    ? 'Watching animation...'
                    : (_drawMode
                        ? 'Draw mode · Finger sketch routes on the court'
                        : (_courtNavigateMode
                            ? 'Pan/zoom mode · Pinch or drag to move the court'
                            : 'Drag the ring on O1–O5 — player follows your finger')),
                style: TextStyle(color: _outline, fontSize: 11, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final screenH = MediaQuery.sizeOf(context).height;
              final maxCourtH = (screenH * 0.58).clamp(460.0, 760.0);
              final maxCourtW = c.maxWidth;

              // Regulation full court in landscape: 94 ft length × 50 ft width.
              double w = maxCourtW;
              double h = w * 50 / 94;
              if (h > maxCourtH) {
                h = maxCourtH;
                w = h * 94 / 50;
              }

              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: (_draggingSlot != null || _drawMode || _courtNavigateMode)
                              ? _primary
                              : Colors.white10,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Builder(
                          builder: (context) {
                            final court = SizedBox(
                              key: _courtKey,
                              width: w,
                              height: h,
                              child: Stack(
                                fit: StackFit.expand,
                                clipBehavior: Clip.none,
                                children: [
                                  ListenableBuilder(
                                    listenable: _playback,
                                    builder: (context, _) {
                                      return TacticalCourtCanvas(
                                        frame: _playback.frame,
                                        ballOwnerSlot: _playback.ballOwnerSlot,
                                        maxHeight: h,
                                        currentStep: _playback.currentStep,
                                        animationProgress: _playback.animationProgress,
                                      );
                                    },
                                  ),
                                  if (_drawStrokes.isNotEmpty)
                                    IgnorePointer(
                                      child: CustomPaint(
                                        painter: _FingerDrawPainter(strokes: _drawStrokes),
                                        size: Size(w, h),
                                      ),
                                    ),
                                  // Visible drag handles on each offense player.
                                  if (!_isPlayerMode && !_drawMode && !_courtNavigateMode)
                                    ListenableBuilder(
                                      listenable: _playback,
                                      builder: (context, _) {
                                        return Stack(
                                          children: _buildOffenseDragHandles(w, h),
                                        );
                                      },
                                    ),
                                  if (_drawMode)
                                    Positioned.fill(
                                      child: Listener(
                                        behavior: HitTestBehavior.opaque,
                                        onPointerDown: (e) => _onDrawPointerDown(e, w, h),
                                        onPointerMove: (e) => _onDrawPointerMove(e, w, h),
                                        onPointerUp: (_) => _endPointerInteraction(),
                                        onPointerCancel: (_) => _endPointerInteraction(),
                                        child: const ColoredBox(color: Colors.transparent),
                                      ),
                                    ),
                                ],
                              ),
                            );

                            if (_courtNavigateMode && !_drawMode) {
                              return InteractiveViewer(
                                panEnabled: true,
                                scaleEnabled: true,
                                minScale: 0.5,
                                maxScale: 3.0,
                                child: court,
                              );
                            }
                            return court;
                          },
                        ),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _playbackSequenceActiveUi,
                      builder: (context, seqActive, _) {
                        if (!seqActive) return const SizedBox.shrink();
                        return Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
                            ),
                            child: const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: _playbackSequenceActiveUi,
            builder: (context, seqActive, _) {
              if (seqActive) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListenableBuilder(
                      listenable: _playback,
                      builder: (context, _) {
                        if (!_playback.isAnimating) {
                          return const SizedBox(width: 48, height: 48);
                        }
                        return IconButton(
                          tooltip: _playback.isPaused ? 'Resume' : 'Pause',
                          icon: Icon(
                            _playback.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            color: _primary,
                            size: 42,
                          ),
                          onPressed: () {
                            if (_playback.isPaused) {
                              _playback.resumePlayback();
                            } else {
                              _playback.pausePlayback();
                            }
                          },
                        );
                      },
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isPlayerMode) ...[
                    TextField(
                      controller: _textCtrl,
                      focusNode: _commandFocus,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type a flow, or tap the mic and say it — then tap RECORD FLOW',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
                        filled: true,
                        fillColor: _surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _voiceUiActive ? _primary.withValues(alpha: 0.55) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _primary.withValues(alpha: 0.9), width: 2),
                        ),
                      ),
                      onSubmitted: _runCommand,
                    ),
                    if (_voiceUiActive) ...[
                      const SizedBox(height: 10),
                      _buildVoiceSessionBanner(),
                    ],
                    if (_isTranscribing) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _primary.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _transcribeProgress > 0
                                    ? 'CONVERTING YOUR VOICE TO TEXT… $_transcribeProgress%'
                                    : 'CONVERTING YOUR VOICE TO TEXT…',
                                style: const TextStyle(
                                  color: _primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ListenableBuilder(
                      listenable: _playback,
                      builder: (context, _) {
                        final busy = _playback.isPlaybackSequenceActive || _isParsingCommand || _isTranscribing;
                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: busy ? Colors.grey : _primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                                onPressed: busy
                                    ? null
                                    : () async {
                                        await _finalizeVoiceSession();
                                        await _runCommand(_textCtrl.text);
                                      },
                                child: _isParsingCommand
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                      )
                                    : Text(_playback.isPlaybackSequenceActive ? 'ANIMATING...' : 'RECORD FLOW', style: const TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_playback.isAnimating)
                              IconButton(
                                onPressed: () {
                                  if (_playback.isPaused) {
                                    _playback.resumePlayback();
                                  } else {
                                    _playback.pausePlayback();
                                  }
                                },
                                icon: Icon(_playback.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: _primary, size: 42),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: busy ? null : _toggleVoiceCommand,
                              tooltip: _voiceUiActive
                                  ? 'Stop and transcribe locally'
                                  : 'Speak your flow — then tap RECORD FLOW',
                              icon: Icon(
                                _voiceUiActive ? Icons.mic_rounded : Icons.mic_none_outlined,
                                color: busy
                                    ? Colors.grey
                                    : (_voiceUiActive
                                        ? _primary
                                        : (_whisperReady ? _primary.withValues(alpha: 0.65) : _outline.withValues(alpha: 0.55))),
                                size: 34,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: busy ? null : () => _playback.playRecordedSession(),
                              icon: const Icon(Icons.replay_circle_filled, color: _primary, size: 42),
                            ),
                          ],
                        );
                      },
                    ),
                    if (_micHint != null && _micHint!.trim().isNotEmpty && !_voiceUiActive && !_isTranscribing) ...[
                      const SizedBox(height: 8),
                      Text(
                        _micHint!,
                        style: const TextStyle(color: _outline, fontSize: 11),
                      ),
                    ],
                    if (_displayVoiceClips.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      CoachVoiceClipsPanel(
                        clips: _displayVoiceClips,
                        title: _isPlayerMode ? 'COACH VOICE NOTES' : 'YOUR VOICE RECORDINGS',
                        subtitle: _isPlayerMode
                            ? 'Replay what the coach said while building this tactic.'
                            : 'These clips save with the tactic so players can replay your instructions.',
                        accentColor: _primary,
                        surfaceColor: _surface,
                        outlineColor: _outline,
                      ),
                    ],
                  ],
                  if (_isPlayerMode && _displayVoiceClips.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    CoachVoiceClipsPanel(
                      clips: _displayVoiceClips,
                      title: 'COACH VOICE NOTES',
                      subtitle: 'Replay coach instructions for this play.',
                      accentColor: _primary,
                      surfaceColor: _surface,
                      outlineColor: _outline,
                    ),
                  ],
                  if (!_isViewingSavedPlayback) ...[
                    const SizedBox(height: 24),
                    Builder(
                      builder: (context) {
                        final live = suggestNextActions(
                          formation: _playback.formation,
                          ballOwnerSlot: _playback.ballOwnerSlot,
                          recentEvents: _playback.timeline.map((e) => e.kind.name).toList(),
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Next Action Suggestions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Space Grotesk', letterSpacing: 0.5)),
                            const SizedBox(height: 16),
                            ...live.map((s) => Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: _surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _primary.withValues(alpha: 0.15)),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isPlayerMode
                                            ? null
                                            : () {
                                                _textCtrl.text = s.sampleCommand;
                                                _runCommand(s.sampleCommand);
                                              },
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                                    child: const Icon(Icons.auto_awesome, color: _primary, size: 16),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(child: Text(s.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(s.reason, style: const TextStyle(color: _outline, fontSize: 13, height: 1.5)),
                                              const SizedBox(height: 16),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.keyboard_command_key, color: _outline, size: 14),
                                                    const SizedBox(width: 10),
                                                    Expanded(child: Text(s.sampleCommand, style: const TextStyle(color: _primary, fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500))),
                                                    const Icon(Icons.play_circle_outline, color: _primary, size: 18),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        );
                      },
                    ),
                  ],
                  if (!_isPlayerMode) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _playback.reset();
                          setState(() {
                            _drawStrokes.clear();
                            _activeStroke = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('RESET BOARD', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Finger-drawn strokes in normalized court coordinates (0–1).
class _FingerDrawPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _FingerDrawPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFFFFD900)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()
      ..color = const Color(0xFFFFD900)
      ..style = PaintingStyle.fill;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final points = stroke.map((n) => CourtSlots.normToPixel(n, size)).toList();
      if (points.length < 2) {
        canvas.drawCircle(points.first, 2.5, dotPaint);
        continue;
      }
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FingerDrawPainter oldDelegate) => true;
}
