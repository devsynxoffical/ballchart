import 'dart:async' show unawaited;
import 'dart:math' show min, sin, pi;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException, HapticFeedback;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/services/api_service.dart';
import '../../../core/services/voice_note_service.dart';
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
  final bool returnOnSave;

  const TacticalLabScreen({
    super.key, 
    this.battleId, 
    this.initialPlayerMode = false,
    this.initialSteps,
    this.returnOnSave = false,
  });

  @override
  State<TacticalLabScreen> createState() => _TacticalLabScreenState();
}

class _TacticalLabScreenState extends State<TacticalLabScreen> with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _commandFocus = FocusNode();
  final _playback = TacticalPlaybackController();
  final _stt = stt.SpeechToText();
  bool _sttReady = false;
  bool _listening = false;
  /// True after user taps mic until the platform reports not listening (covers connect latency).
  bool _voiceSessionPending = false;
  String? _micHint;
  final _api = ApiService();
  final _voiceNoteSvc = VoiceNoteService();
  final List<VoiceClip> _tacticalVoiceClips = [];

  int? _draggingSlot;
  /// Throttle drag → recorded keyframes so replay stays seconds, not minutes.
  DateTime? _lastDragKeyframeAt;
  Offset? _lastDragKeyframeNorm;
  Offset? _dragPointerStartNorm;
  static const Duration _dragKeyframeMinInterval = Duration(milliseconds: 40);
  static const double _dragKeyframeMinDistance = 0.013;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPlaybackSequenceUi();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final role = (context.read<ProfileViewmodel>().user?.role ?? '').toLowerCase();
      if (role == 'player' && !_isPlayerMode) {
        setState(() => _isPlayerMode = true);
      }
      await _setupSpeech();
      _api.connectSocket();
    });
  }

  Future<void> _setupSpeech() async {
    if (kIsWeb || _isPlayerMode) return;
    final ok = await _stt.initialize(
      onError: (e) {
        if (!mounted) return;
        _micPulseCtrl.stop();
        setState(() {
          _micHint = 'Speech error: ${e.errorMsg}';
          _listening = false;
          _voiceSessionPending = false;
        });
      },
      onStatus: (status) {
        if (!mounted) return;
        final now = status == stt.SpeechToText.listeningStatus;
        if (now) {
          _micPulseCtrl.repeat(reverse: true);
        } else {
          _micPulseCtrl.stop();
          _micPulseCtrl.value = 0;
        }
        setState(() {
          _listening = now;
          if (now) {
            _voiceSessionPending = false;
            _micHint = null;
          }
        });
      },
    );
    setState(() {
      _sttReady = ok;
      _micHint = ok ? null : 'Speech recognition unavailable.';
    });
  }

  String _cleanVoiceTranscript(String text) {
    String cleaned = text;
    
    // Auto-correct common speech-to-text typos/mishearings
    cleaned = cleaned.replaceAll(RegExp(r'\b(palyer|palyar|playar|playur|payler|plater)\b', caseSensitive: false), 'player');
    
    // Replace spoken numbers with digits
    final numberMap = {
      'one': '1',
      'two': '2',
      'three': '3',
      'four': '4',
      'five': '5',
    };
    numberMap.forEach((word, digit) {
      cleaned = cleaned.replaceAll(RegExp('\\b(player|defense|defender|d|p|number)\\s+$word\\b', caseSensitive: false), '\$1 $digit');
    });

    // Format to short P1/P2/D1/D2 representation
    cleaned = cleaned.replaceAllMapped(RegExp(r'\bplayer\s+([1-5])\b', caseSensitive: false), (m) => 'P${m[1]}');
    cleaned = cleaned.replaceAllMapped(RegExp(r'\bdefense\s+([1-5])\b', caseSensitive: false), (m) => 'D${m[1]}');
    cleaned = cleaned.replaceAllMapped(RegExp(r'\bdefender\s+([1-5])\b', caseSensitive: false), (m) => 'D${m[1]}');
    cleaned = cleaned.replaceAllMapped(RegExp(r'\bp\s+([1-5])\b', caseSensitive: false), (m) => 'P${m[1]}');
    cleaned = cleaned.replaceAllMapped(RegExp(r'\bd\s+([1-5])\b', caseSensitive: false), (m) => 'D${m[1]}');
    cleaned = cleaned.replaceAllMapped(RegExp(r'\bnumber\s+([1-5])\b', caseSensitive: false), (m) => 'P${m[1]}');

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned;
  }

  Future<void> _toggleVoiceCommand() async {
    if (_isPlayerMode) return;

    if (_listening || _voiceSessionPending) {
      await _stt.stop();
      try {
        final clip = await _voiceNoteSvc.stopRecording();
        if (clip != null && mounted) {
          setState(() => _tacticalVoiceClips.add(clip));
        }
      } catch (_) {}
      _micPulseCtrl.stop();
      _micPulseCtrl.value = 0;
      if (mounted) {
        setState(() {
          _listening = false;
          _voiceSessionPending = false;
          _micHint = _tacticalVoiceClips.isNotEmpty
              ? 'Voice saved (${_tacticalVoiceClips.length} clip${_tacticalVoiceClips.length == 1 ? '' : 's'}). Tap RECORD FLOW or save tactic.'
              : 'Voice capture stopped. Tap mic again to add more, or tap RECORD FLOW.';
        });
      }
      return;
    }

    if (!_sttReady) {
      if (mounted) {
        setState(() => _micHint = 'Speech recognition unavailable.');
      }
      return;
    }

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (mounted) {
          setState(() => _micHint = 'Microphone permission denied.');
        }
        return;
      }
    }

    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        _voiceSessionPending = true;
        _micHint = null;
      });
      FocusScope.of(context).requestFocus(_commandFocus);
    }

    try {
      try {
        await _voiceNoteSvc.startRecording();
      } catch (e) {
        if (mounted) {
          setState(() => _micHint = 'Could not start voice recording: $e');
        }
      }

      final systemLocale = await _stt.systemLocale();
      final localeId = systemLocale?.localeId;

      await _stt.listen(
        localeId: (localeId != null && localeId.isNotEmpty) ? localeId : null,
        listenFor: const Duration(seconds: 90),
        pauseFor: const Duration(seconds: 5),
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          autoPunctuation: true,
        ),
        onResult: (result) {
          final transcript = result.recognizedWords.trim();
          if (!mounted) return;
          if (transcript.isNotEmpty) {
            final cleaned = _cleanVoiceTranscript(transcript);
            _textCtrl.value = TextEditingValue(
              text: cleaned,
              selection: TextSelection.collapsed(offset: cleaned.length),
            );
          }
          setState(() {});
        },
      );
      unawaited(Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (_voiceSessionPending && !_listening) {
          setState(() {
            _voiceSessionPending = false;
            _micHint = 'Listening did not start. Check the microphone and try again.';
          });
        }
      }));
    } on MissingPluginException {
      await _voiceNoteSvc.cancelRecording();
      _micPulseCtrl.stop();
      if (mounted) {
        setState(() {
          _voiceSessionPending = false;
          _listening = false;
          _micHint = 'Speech plugin missing on this build.';
        });
      }
    } catch (e) {
      await _voiceNoteSvc.cancelRecording();
      _micPulseCtrl.stop();
      if (mounted) {
        setState(() {
          _voiceSessionPending = false;
          _listening = false;
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
    _stt.stop();
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

    setState(() {
      _isParsingCommand = true;
    });

    ParsedCoachCommand parsed;
    bool usedGemini = false;

    try {
      final res = await _api.parseVoiceCommand(raw);
      parsed = ParsedCoachCommand.fromJson(res, raw);
      usedGemini = true;
    } catch (e) {
      if (kDebugMode) {
        print('Gemini parsing failed, falling back to local: $e');
      }
      parsed = parseCoachCommand(raw);
    }

    if (!mounted) return;

    setState(() {
      _isParsingCommand = false;
    });

    if (parsed.confidence >= 0.5 && parsed.intent != CoachIntent.unknown) {
      _playback.applyParsedCommand(parsed);
      final stepCount = parsed.steps.length;
      final label = stepCount > 1 ? 'Sequence: $stepCount steps' : 'Command: ${parsed.intent.name.toUpperCase()}';
      final modeLabel = usedGemini ? 'AI' : 'Local';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recognized ($modeLabel): $label', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: _primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        )
      );
    } else if (raw.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Command not recognized. Try "P1 pass to P2"'),
          backgroundColor: Colors.redAccent,
        )
      );
    }
  }

  void _onPointerDown(PointerDownEvent event, double w, double h) {
    if (_isPlayerMode || _playback.isPlaybackSequenceActive) return;
    final local = event.localPosition;
    
    int? foundSlot;
    double minAt = 40.0; 
    for (int i = 0; i < 5; i++) {
      final p = _playback.frame.offenseNorm[i];
      final px = p.dx * w;
      final py = p.dy * h;
      final dist = (Offset(px, py) - local).distance;
      if (dist < minAt) {
        minAt = dist;
        foundSlot = i + 1;
      }
    }
    if (foundSlot != null) {
      final idx = foundSlot - 1;
      final startNorm = _playback.frame.offenseNorm[idx];
      setState(() {
        _draggingSlot = foundSlot;
        _dragPointerStartNorm = startNorm;
        _lastDragKeyframeAt = null;
        _lastDragKeyframeNorm = null;
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event, double w, double h) {
    if (_draggingSlot == null) return;
    final local = event.localPosition;
    final norm = Offset(
      (local.dx / w).clamp(0.0, 1.0),
      (local.dy / h).clamp(0.0, 1.0),
    );
    _playback.updateOffenseDragLive(_draggingSlot!, norm);
    _maybeRecordDragKeyframe(_draggingSlot!, norm, force: false);
  }

  int _dragKeyframeDurationMs(Offset? prev, Offset norm) {
    if (prev == null) return 115;
    final d = (norm - prev).distance;
    return (48 + d * 720).round().clamp(45, 240);
  }

  void _maybeRecordDragKeyframe(int slot, Offset norm, {required bool force}) {
    final now = DateTime.now();
    final prevNorm = _lastDragKeyframeNorm;
    final lastAt = _lastDragKeyframeAt;

    if (!force) {
      if (lastAt != null && now.difference(lastAt) < _dragKeyframeMinInterval) {
        if (prevNorm == null || (norm - prevNorm).distance < _dragKeyframeMinDistance) {
          return;
        }
      } else if (prevNorm != null && (norm - prevNorm).distance < _dragKeyframeMinDistance * 0.65) {
        return;
      }
    } else {
      if (prevNorm != null && (norm - prevNorm).distance < 0.004) return;
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

  void _onPointerUp(PointerUpEvent event) {
    if (_draggingSlot != null) {
      final slot = _draggingSlot!;
      final cur = _playback.frame.offenseNorm[slot - 1];
      final started = _dragPointerStartNorm;
      if (started != null && (cur - started).distance > 0.008) {
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

  Future<void> _savePlaybook() async {
    if (_playback.recordedSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No actions recorded to save.')));
      return;
    }

    final academy = context.read<AcademyProvider>();
    final strategyVm = context.read<StrategyViewmodel>();
    
    // Ensure coach dashboard data is available for team/player assignment.
    if (academy.coachDashboard == null) {
      await academy.loadCoachDashboard(force: true);
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name for the tactic.')));
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

                    final transcript = _textCtrl.text.trim();
                    final voiceClipsMeta = <Map<String, dynamic>>[];
                    String? primaryVoiceUrl;
                    int? primaryVoiceDurationMs;
                    for (final clip in _tacticalVoiceClips) {
                      final url = await _voiceNoteSvc.uploadClip(clip);
                      voiceClipsMeta.add({
                        'url': url,
                        'durationMs': clip.duration.inMilliseconds,
                      });
                      primaryVoiceUrl ??= url;
                      primaryVoiceDurationMs ??= clip.duration.inMilliseconds;
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
                      category: 'tactical',
                      sourceType: voiceClipsMeta.isNotEmpty ? 'voice' : 'tactical_recording',
                      sourceText: transcript.isNotEmpty
                          ? transcript
                          : 'Recorded tactical flow from Tactical Lab',
                      isPublic: true,
                      metadata: metadata,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tactic saved and published to Strategy screen!'),
                          backgroundColor: Colors.green,
                        )
                      );
                      // Also add to local cache for immediate feedback in this session
                      setState(() {
                        _savedPlaybooks.insert(0, {
                          'name': _saveNameCtrl.text,
                          'steps': List<PlayStep>.from(_playback.recordedSteps),
                          'coachTips': _coachTipsCtrl.text,
                        });
                        _saveNameCtrl.clear();
                        _coachTipsCtrl.clear();
                        _tacticalVoiceClips.clear();
                      });
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
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
    setState(() {
      _activePlaybook = pb;
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
                    Text(
                      active ? 'SPEAK NOW' : 'GET READY',
                      style: TextStyle(
                        color: _primary.withValues(alpha: 0.98),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      active
                          ? 'Your full flow is typed live in the box above as you talk. You can pause up to about 5 seconds between phrases. Tap the mic again when you are done.'
                          : 'Opening the microphone — get your sentence ready; you will see SPEAK NOW when it is time to talk.',
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
        title: Text(_isPlayerMode ? 'PLAYBOOK LIBRARY' : 'TACTICAL LAB', style: const TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        actions: [
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
                _isPlayerMode ? 'Watching animation...' : 'Coach Mode · Full court active · Drag to design',
                style: TextStyle(color: _outline, fontSize: 11, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final targetH = (MediaQuery.sizeOf(context).height * 0.42).clamp(280.0, 520.0);
              final w = min(c.maxWidth, targetH * 94 / 50);
              final h = w * 50 / 94;
              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _draggingSlot != null ? _primary : Colors.white10, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Listener(
                          onPointerDown: (e) => _onPointerDown(e, w, h),
                          onPointerMove: (e) => _onPointerMove(e, w, h),
                          onPointerUp: _onPointerUp,
                          child: InteractiveViewer(
                            panEnabled: _draggingSlot == null,
                            scaleEnabled: _draggingSlot == null,
                            minScale: 0.5,
                            maxScale: 3.0,
                            child: SizedBox(
                              width: w,
                              height: h,
                              child: RepaintBoundary(
                                child: ListenableBuilder(
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
                              ),
                            ),
                          ),
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
                        hintText: 'Type a flow, or tap the mic and say it — text appears as you speak',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
                        filled: true,
                        fillColor: _surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: (_listening || _voiceSessionPending) ? _primary.withValues(alpha: 0.55) : Colors.transparent,
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
                    if (_listening || _voiceSessionPending) ...[
                      const SizedBox(height: 10),
                      _buildVoiceSessionBanner(),
                    ],
                    const SizedBox(height: 12),
                    ListenableBuilder(
                      listenable: _playback,
                      builder: (context, _) {
                        final busy = _playback.isPlaybackSequenceActive || _isParsingCommand;
                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: busy ? Colors.grey : _primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                                onPressed: busy ? null : () => _runCommand(_textCtrl.text),
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
                              tooltip: _listening
                                  ? 'Stop listening (keeps your text)'
                                  : _voiceSessionPending
                                      ? 'Connecting microphone…'
                                      : 'Speak your flow — types live in the box',
                              icon: Icon(
                                (_listening || _voiceSessionPending) ? Icons.mic_rounded : Icons.mic_none_outlined,
                                color: busy
                                    ? Colors.grey
                                    : ((_listening || _voiceSessionPending)
                                        ? _primary
                                        : (_sttReady ? _primary.withValues(alpha: 0.65) : _outline.withValues(alpha: 0.55))),
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
                    if (_micHint != null && _micHint!.trim().isNotEmpty && !_listening && !_voiceSessionPending) ...[
                      const SizedBox(height: 8),
                      Text(
                        _micHint!,
                        style: const TextStyle(color: _outline, fontSize: 11),
                      ),
                    ],
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
                        onPressed: () => _playback.reset(),
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
