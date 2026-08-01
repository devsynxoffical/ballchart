import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ballchart/core/utils/app_messenger.dart';

import '../../services/api_service.dart';
import '../../services/voice_note_service.dart';

class VoiceNoteBubble extends StatefulWidget {
  const VoiceNoteBubble({
    super.key,
    required this.voiceUrl,
    required this.durationMs,
    this.mine = false,
    this.localPath,
    this.uploading = false,
  });

  final String voiceUrl;
  final int durationMs;
  final bool mine;
  final String? localPath;
  final bool uploading;

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble> {
  final VoiceNoteService _voice = VoiceNoteService.playback();
  bool _playing = false;
  bool _busy = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  String get _sourceKey {
    if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      return widget.localPath!;
    }
    if (widget.voiceUrl.isNotEmpty) {
      return ApiService.resolveMediaUrl(widget.voiceUrl);
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _total = Duration(milliseconds: widget.durationMs.clamp(0, 5999000));

    _stateSub = _voice.playerStateStream.listen((state) {
      if (!mounted) return;
      final active = _voice.isPlayingSource(_sourceKey);
      setState(() {
        _playing = active;
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          if (_voice.currentlyPlayingSource == _sourceKey || !active) {
            _position = Duration.zero;
            _playing = false;
          }
        }
      });
    });

    _positionSub = _voice.positionStream.listen((pos) {
      if (!mounted || !_voice.isPlayingSource(_sourceKey)) return;
      setState(() => _position = pos);
    });

    _durationSub = _voice.durationStream.listen((dur) {
      if (!mounted || dur.inMilliseconds <= 0) return;
      if (_voice.currentlyPlayingSource == _sourceKey ||
          _voice.currentlyPlayingSource == null) {
        setState(() => _total = dur);
      }
    });
  }

  @override
  void didUpdateWidget(covariant VoiceNoteBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationMs != widget.durationMs && !_playing) {
      _total = Duration(milliseconds: widget.durationMs.clamp(0, 5999000));
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _voice.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final totalSec = d.inSeconds.clamp(0, 5999);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final totalMs = _total.inMilliseconds;
    if (totalMs <= 0) return 0;
    return (_position.inMilliseconds / totalMs).clamp(0.0, 1.0);
  }

  Future<void> _togglePlay() async {
    if (_busy) return;
    if (_sourceKey.isEmpty) {
      _showPlayError('No audio available for this clip yet.');
      return;
    }
    if (_playing) {
      await _voice.stopPlayback();
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
      return;
    }

    setState(() => _busy = true);
    try {
      if (widget.localPath != null && widget.localPath!.isNotEmpty) {
        await _voice.playLocal(widget.localPath!);
      } else if (widget.voiceUrl.isNotEmpty) {
        await _voice.playUrl(widget.voiceUrl);
      } else {
        throw Exception('No audio available for this clip yet.');
      }
      if (mounted) setState(() => _playing = true);
    } catch (e) {
      if (mounted) {
        setState(() => _playing = false);
        _showPlayError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showPlayError(String message) {
    AppMessenger.show(
      context,
      message: message,
      kind: AppMessageKind.error,
      title: 'Playback',
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.mine ? const Color(0xFFFFD900) : Colors.white70;
    final resolved = widget.voiceUrl.isNotEmpty ? ApiService.resolveMediaUrl(widget.voiceUrl) : '';
    final displayDuration = _playing ? _position : _total;
    final barCount = 28;

    return InkWell(
      onTap: _sourceKey.isEmpty ? null : _togglePlay,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withValues(alpha: 0.2),
              child: Icon(
                _busy
                    ? Icons.hourglass_top_rounded
                    : (_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 22,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(barCount, (i) {
                    final barProgress = (i + 1) / barCount;
                    final filled = barProgress <= _progress;
                    final idleHeights = [0.35, 0.55, 0.75, 0.5, 0.9, 0.6, 0.45, 0.8];
                    final h = 4.0 + (idleHeights[i % idleHeights.length] * 14);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.6),
                        child: Align(
                          alignment: Alignment.center,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            height: filled && _playing ? h + 2 : h,
                            decoration: BoxDecoration(
                              color: filled
                                  ? accent
                                  : Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatDuration(displayDuration),
              style: TextStyle(
                color: Colors.white.withValues(alpha: _playing ? 0.95 : 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (widget.uploading) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.cloud_upload_outlined,
                size: 14,
                color: accent.withValues(alpha: 0.7),
              ),
            ] else if (resolved.isEmpty &&
                (widget.localPath == null || widget.localPath!.isEmpty)) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: accent.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
