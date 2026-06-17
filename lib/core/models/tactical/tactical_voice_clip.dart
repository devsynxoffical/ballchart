/// Saved or in-progress coach voice note attached to a tactic.
class TacticalVoiceClip {
  final String? url;
  final String? localPath;
  final int durationMs;
  final String transcript;
  final DateTime? recordedAt;

  const TacticalVoiceClip({
    this.url,
    this.localPath,
    required this.durationMs,
    this.transcript = '',
    this.recordedAt,
  });

  bool get canPlay =>
      (url != null && url!.isNotEmpty) || (localPath != null && localPath!.isNotEmpty);

  factory TacticalVoiceClip.fromJson(Map<String, dynamic> json) {
    return TacticalVoiceClip(
      url: json['url']?.toString(),
      localPath: json['localPath']?.toString(),
      durationMs: json['durationMs'] is num ? (json['durationMs'] as num).toInt() : 0,
      transcript: (json['transcript'] ?? '').toString().trim(),
      recordedAt: DateTime.tryParse((json['recordedAt'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        if (url != null && url!.isNotEmpty) 'url': url,
        if (localPath != null && localPath!.isNotEmpty) 'localPath': localPath,
        'durationMs': durationMs,
        if (transcript.isNotEmpty) 'transcript': transcript,
        if (recordedAt != null) 'recordedAt': recordedAt!.toIso8601String(),
      };

  static List<TacticalVoiceClip> listFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return const [];

    final out = <TacticalVoiceClip>[];
    final raw = metadata['voiceClips'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final clip = TacticalVoiceClip.fromJson(Map<String, dynamic>.from(item));
          if (clip.canPlay || clip.transcript.isNotEmpty) out.add(clip);
        }
      }
    }

    if (out.isEmpty) {
      final legacyUrl = (metadata['voiceUrl'] ?? '').toString();
      if (legacyUrl.isNotEmpty) {
        out.add(
          TacticalVoiceClip(
            url: legacyUrl,
            durationMs: metadata['voiceDurationMs'] is num
                ? (metadata['voiceDurationMs'] as num).toInt()
                : 0,
            transcript: (metadata['voiceTranscript'] ?? '').toString().trim(),
          ),
        );
      }
    }

    return out;
  }
}

/// In-session recording before upload.
class TacticalVoiceRecording {
  final String localPath;
  final Duration duration;
  final String transcript;
  final DateTime recordedAt;

  TacticalVoiceRecording({
    required this.localPath,
    required this.duration,
    required this.transcript,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  TacticalVoiceClip toClip({String? uploadedUrl}) => TacticalVoiceClip(
        url: uploadedUrl,
        localPath: localPath,
        durationMs: duration.inMilliseconds,
        transcript: transcript,
        recordedAt: recordedAt,
      );
}
