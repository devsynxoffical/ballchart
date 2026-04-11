import 'dart:math' show min;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/services/api_service.dart';
import '../../../core/tactical/tactical_ai_suggestions.dart';
import '../../../core/tactical/tactical_animation_engine.dart';
import '../../../core/tactical/tactical_court_canvas.dart';
import '../../../core/tactical/tactical_socket_sync.dart';
import '../../../core/tactical/scenario_interpreter.dart';
import '../../../core/tactical/voice_command_parser.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';

/// Phase 4–5 lab: text + voice commands → parser → animation; optional socket sync when [battleId] is set.
class TacticalLabScreen extends StatefulWidget {
  final String? battleId;

  const TacticalLabScreen({super.key, this.battleId});

  @override
  State<TacticalLabScreen> createState() => _TacticalLabScreenState();
}

class _TacticalLabScreenState extends State<TacticalLabScreen> {
  final _textCtrl = TextEditingController();
  final _playback = TacticalPlaybackController();
  final _stt = stt.SpeechToText();
  bool _sttReady = false;
  bool _listening = false;
  String? _micHint;
  bool _autoRunOnFinal = true;
  ParsedCoachCommand? _lastParse;
  late ScenarioSummary _scenario;
  final _api = ApiService();

  static const Color _primary = Color(0xFFFFD900);
  static const Color _bg = Color(0xFF131313);
  static const Color _surface = Color(0xFF201F1F);
  static const Color _outline = Color(0xFF9D8F79);

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// `true` = granted, `false` = denied, `null` = [permission_handler] not registered — use speech_to_text only.
  Future<bool?> _requestMicPermission() async {
    if (!_isMobile) return true;
    try {
      final s = await Permission.microphone.request();
      return s.isGranted;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool?> _micPermissionGrantedOrUnknown() async {
    if (!_isMobile) return true;
    try {
      final s = await Permission.microphone.status;
      return s.isGranted;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _scenario = interpretScenario('', parseCoachCommand(''));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _setupSpeech();
      _api.connectSocket();
      final s = _api.socket;
      if (s != null && widget.battleId != null && widget.battleId!.isNotEmpty) {
        TacticalSocketSync.joinBattleRoom(s, widget.battleId!);
        TacticalSocketSync.onRemoteFrames(s, (data) {
          final cmd = data['command']?.toString();
          if (cmd != null && cmd.isNotEmpty) {
            _playback.applyParsedCommand(parseCoachCommand(cmd));
            if (mounted) setState(() {});
          }
        });
      }
    });
  }

  Future<void> _setupSpeech() async {
    if (kIsWeb) {
      setState(() {
        _sttReady = false;
        _micHint = 'Voice is not supported in the browser. Type a command below.';
      });
      return;
    }

    if (_isMobile) {
      final perm = await _requestMicPermission();
      if (perm == false) {
        setState(() {
          _sttReady = false;
          _micHint = 'Microphone permission is required for voice commands.';
        });
        return;
      }
      // perm == true or null (MissingPluginException): continue; speech_to_text may still prompt the OS.
    }

    final ok = await _stt.initialize(
      onError: (e) {
        if (!mounted) return;
        final msg = e.errorMsg;
        setState(() => _micHint = 'Speech error: $msg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech: $msg'), backgroundColor: Colors.red.shade800),
        );
      },
      onStatus: (status) {
        if (!mounted) return;
        setState(() {
          final listening = status == stt.SpeechToText.listeningStatus;
          _listening = listening;
          if (status == stt.SpeechToText.doneStatus || status == stt.SpeechToText.notListeningStatus) {
            _listening = false;
          }
        });
      },
      debugLogging: kDebugMode,
    );

    if (!mounted) return;
    setState(() {
      _sttReady = ok;
      _micHint = ok
          ? null
          : 'Speech recognition is not available on this device (try a physical phone, or type commands). '
              'If you added plugins recently, stop the app and run a full rebuild (not hot reload).';
    });
  }

  @override
  void dispose() {
    _stt.stop();
    _textCtrl.dispose();
    _playback.dispose();
    super.dispose();
  }

  void _runCommand(String raw) {
    final parsed = parseCoachCommand(raw);
    final scenario = interpretScenario(raw, parsed);
    setState(() {
      _lastParse = parsed;
      _scenario = scenario;
    });
    if (parsed.confidence >= 0.5 && parsed.intent != CoachIntent.unknown) {
      _playback.applyParsedCommand(parsed);
      _emitSocket(raw);
    }
  }

  void _emitSocket(String raw) {
    final sock = _api.socket;
    final bid = widget.battleId;
    if (sock != null && bid != null && bid.isNotEmpty) {
      TacticalSocketSync.emitAnimationFrame(sock, bid, {
        'command': raw,
        'ballOwner': _playback.ballOwnerSlot,
        'formation': _playback.formation.name,
      });
    }
  }

  Future<void> _openMicSettings() async {
    try {
      await openAppSettings();
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Open system Settings → Apps → BallChart → Permissions → Microphone')),
        );
      }
    }
  }

  Future<void> _toggleListen() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use keyboard on web.')),
      );
      return;
    }

    if (_listening) {
      await _stt.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (!_sttReady) {
      await _setupSpeech();
      if (!_sttReady) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_micHint ?? 'Speech not available'),
            action: _isMobile
                ? SnackBarAction(label: 'Settings', onPressed: _openMicSettings)
                : null,
          ),
        );
        return;
      }
    }

    if (_isMobile) {
      final before = await _micPermissionGrantedOrUnknown();
      if (before == false) {
        final req = await _requestMicPermission();
        if (req == false) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone permission denied'),
              action: SnackBarAction(label: 'Settings', onPressed: _openMicSettings),
            ),
          );
          return;
        }
      }
    }

    try {
      setState(() => _listening = true);
      await _stt.listen(
        onResult: (r) {
          _textCtrl.text = r.recognizedWords;
          if (_autoRunOnFinal && r.finalResult && r.recognizedWords.trim().isNotEmpty) {
            _runCommand(r.recognizedWords.trim());
          }
          if (mounted) setState(() {});
        },
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _listening = false;
          _micHint = 'Could not start listening: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listen failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileViewmodel>().user;
    final username = profile?.username;
    final suggestions = suggestNextActions(
      formation: _playback.formation,
      ballOwnerSlot: _playback.ballOwnerSlot,
      recentEvents: _playback.timeline.map((e) => e.kind.name).toList(),
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Tactical Lab', style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w800)),
        actions: [
          if (username != null && username.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  username,
                  style: const TextStyle(color: _outline, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _playback,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full court · O1–O5 = offense (south) · D1–D5 = defense (north) · Pinch to zoom',
                  style: TextStyle(color: _outline.withValues(alpha: 0.9), fontSize: 11, height: 1.35),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, c) {
                    final screenH = MediaQuery.sizeOf(context).height;
                    final targetH = (screenH * 0.42).clamp(280.0, 520.0);
                    final maxW = c.maxWidth;
                    final w = min(maxW, targetH * 94 / 50);
                    final h = w * 50 / 94;
                    return Center(
                      child: InteractiveViewer(
                        minScale: 0.65,
                        maxScale: 2.75,
                        boundaryMargin: const EdgeInsets.all(48),
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: TacticalCourtCanvas(
                            frame: _playback.frame,
                            ballOwnerSlot: _playback.ballOwnerSlot,
                            maxHeight: h,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _primary.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology_outlined, color: _primary, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Scenario',
                              style: TextStyle(color: _primary.withValues(alpha: 0.95), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              _scenario.phase,
                              style: const TextStyle(color: _outline, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _scenario.headline,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Space Grotesk'),
                      ),
                      const SizedBox(height: 10),
                      ..._scenario.bullets.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ', style: TextStyle(color: _primary.withValues(alpha: 0.9))),
                              Expanded(child: Text(b, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.battleId != null)
                  Text('Socket room: battle ${widget.battleId}', style: const TextStyle(color: _outline, fontSize: 11)),
                if (_micHint != null) ...[
                  const SizedBox(height: 8),
                  Text(_micHint!, style: const TextStyle(color: _outline, fontSize: 12, height: 1.35)),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-run when you finish speaking', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  value: _autoRunOnFinal,
                  activeThumbColor: _primary,
                  onChanged: (v) => setState(() => _autoRunOnFinal = v),
                ),
                TextField(
                  controller: _textCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a command (or use mic)…',
                    hintStyle: TextStyle(color: _outline.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: _surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onSubmitted: _runCommand,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _runCommand(_textCtrl.text),
                        child: const Text('RUN COMMAND', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      child: IconButton(
                        tooltip: _listening ? 'Stop' : 'Speak',
                        color: _primary,
                        onPressed: kIsWeb ? null : _toggleListen,
                        icon: Icon(_listening ? Icons.stop : Icons.mic),
                      ),
                    ),
                  ],
                ),
                if (!_sttReady && !kIsWeb)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: _setupSpeech,
                      child: const Text('Retry speech setup'),
                    ),
                  ),
                const SizedBox(height: 20),
                if (_lastParse != null) ...[
                  Text(
                    'Intent: ${_lastParse!.intent.name}  ·  conf ${_lastParse!.confidence.toStringAsFixed(2)}',
                    style: const TextStyle(color: _primary, fontWeight: FontWeight.bold),
                  ),
                  if (_lastParse!.alternatives.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Did you mean…', style: TextStyle(color: _outline, fontSize: 11)),
                    Wrap(
                      spacing: 8,
                      children: _lastParse!.alternatives
                          .map((a) => ActionChip(
                                label: Text(a, style: const TextStyle(fontSize: 12)),
                                onPressed: () {
                                  _textCtrl.text = a;
                                  _runCommand(a);
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                const Text('Suggestions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                ...suggestions.map((s) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(s.reason, style: const TextStyle(color: _outline, fontSize: 12, height: 1.3)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _textCtrl.text = s.sampleCommand;
                              _runCommand(s.sampleCommand);
                            },
                            child: Text('Try: ${s.sampleCommand}', style: const TextStyle(color: _primary)),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _playback.reset(),
                  child: const Text('Reset court'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
