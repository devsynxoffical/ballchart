import 'package:flutter/material.dart';

import '../../models/tactical/tactical_voice_clip.dart';
import '../messaging/voice_note_bubble.dart';

/// Replayable coach voice notes attached to a saved tactic.
class CoachVoiceClipsPanel extends StatelessWidget {
  const CoachVoiceClipsPanel({
    super.key,
    required this.clips,
    this.title = 'COACH VOICE',
    this.subtitle,
    this.accentColor = const Color(0xFFFFD900),
    this.surfaceColor = const Color(0xFF201F1F),
    this.outlineColor = const Color(0xFF9D8F79),
  });

  final List<TacticalVoiceClip> clips;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final Color surfaceColor;
  final Color outlineColor;

  @override
  Widget build(BuildContext context) {
    if (clips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: accentColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(color: outlineColor.withValues(alpha: 0.9), fontSize: 12, height: 1.35),
          ),
        ],
        const SizedBox(height: 12),
        ...List.generate(clips.length, (i) {
          final clip = clips[i];
          return Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: i == clips.length - 1 ? 0 : 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CLIP ${i + 1}',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (!clip.canPlay) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Audio pending upload',
                        style: TextStyle(color: outlineColor.withValues(alpha: 0.75), fontSize: 10),
                      ),
                    ],
                  ],
                ),
                if (clip.transcript.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    clip.transcript,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
                  ),
                ],
                if (clip.canPlay) ...[
                  const SizedBox(height: 12),
                  VoiceNoteBubble(
                    voiceUrl: clip.url ?? '',
                    durationMs: clip.durationMs,
                    localPath: clip.localPath,
                    mine: false,
                    audioExt: 'wav',
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
