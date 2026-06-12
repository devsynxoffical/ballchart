import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/voice_note_service.dart';

class VoiceNoteBubble extends StatefulWidget {
  const VoiceNoteBubble({
    super.key,
    required this.voiceUrl,
    required this.durationMs,
    this.mine = false,
    this.localPath,
  });

  final String voiceUrl;
  final int durationMs;
  final bool mine;
  final String? localPath;

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble> {
  final VoiceNoteService _voice = VoiceNoteService();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _voice.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  String _formatDuration(int ms) {
    final totalSec = (ms / 1000).round().clamp(0, 5999);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _voice.stopPlayback();
      return;
    }
    if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      await _voice.playLocal(widget.localPath!);
    } else if (widget.voiceUrl.isNotEmpty) {
      await _voice.playUrl(widget.voiceUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.mine ? const Color(0xFFFFD900) : Colors.white70;
    final resolved = widget.voiceUrl.isNotEmpty ? ApiService.resolveMediaUrl(widget.voiceUrl) : '';

    return InkWell(
      onTap: _togglePlay,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.2),
            child: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _playing ? 0.65 : 0.25,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(widget.durationMs),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
          ),
          if (resolved.isEmpty && (widget.localPath == null || widget.localPath!.isEmpty))
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}
