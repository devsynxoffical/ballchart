import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/basketball_strategy.dart';
import '../../../core/models/strategy_model.dart';
import '../../../core/tactical/tactical_entities.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/share_utils.dart';
import '../../../core/utils/strategy_pdf_generator.dart';
import '../../../core/models/tactical/tactical_voice_clip.dart';
import '../../../core/widgets/tactics/coach_voice_clips_panel.dart';
import '../../tactics/view/tactical_lab_screen.dart';

class StrategyDetailScreen extends StatelessWidget {
  final StrategyModel strategy;

  const StrategyDetailScreen({super.key, required this.strategy});

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF201F1F);
  static const Color outlineColor = Color(0xFF9D8F79);

  bool _strategyHasVideo(StrategyModel s) => s.videoUrl.trim().isNotEmpty;

  String _normalizedVideoUrl(String raw) {
    final resolved = ApiService.resolveMediaUrl(raw).trim();
    if (resolved.isEmpty) return '';
    final uri = Uri.tryParse(resolved);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) return '';
    return uri.toString();
  }

  bool _isLikelyUnsupportedPageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('facebook.com') ||
        host.contains('instagram.com') ||
        host.contains('tiktok.com');
  }

  String? _extractYoutubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final segs = uri.pathSegments;
      if (segs.isNotEmpty && segs.first.trim().isNotEmpty) return segs.first.trim();
    }
    if (host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.trim().isNotEmpty) return v.trim();
      final segs = uri.pathSegments;
      final idx = segs.indexOf('embed');
      if (idx != -1 && idx + 1 < segs.length && segs[idx + 1].trim().isNotEmpty) {
        return segs[idx + 1].trim();
      }
      final shortsIdx = segs.indexOf('shorts');
      if (shortsIdx != -1 && shortsIdx + 1 < segs.length && segs[shortsIdx + 1].trim().isNotEmpty) {
        return segs[shortsIdx + 1].trim();
      }
    }
    return null;
  }

  List<PlayStep> _parsePlaySteps(Map<String, dynamic> metadata) {
    final rawSteps = metadata['playSteps'];
    if (rawSteps is! List) return const <PlayStep>[];
    final steps = <PlayStep>[];
    for (final step in rawSteps) {
      if (step is Map) {
        try {
          steps.add(PlayStep.fromJson(Map<String, dynamic>.from(step)));
        } catch (_) {
          // Skip malformed step payloads to keep detail screen resilient.
        }
      }
    }
    return steps;
  }

  Future<void> _playVideo(BuildContext context, String videoUrl) async {
    final youtubeId = _extractYoutubeId(videoUrl);
    if (youtubeId != null) {
      final ytUri = Uri.parse('https://www.youtube.com/watch?v=$youtubeId');
      try {
        final opened = await launchUrl(ytUri, mode: LaunchMode.externalApplication);
        if (opened) return;
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open YouTube app. Link copied.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        await Clipboard.setData(ClipboardData(text: ytUri.toString()));
      }
      return;
    }

    if (_isLikelyUnsupportedPageUrl(videoUrl)) {
      final uri = Uri.parse(videoUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    showDialog(context: context, builder: (_) => _VideoPlayerDialog(videoUrl: videoUrl));
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _normalizedVideoUrl(strategy.videoUrl);
    final isSocial = _isLikelyUnsupportedPageUrl(resolved);
    final hasVideo = _strategyHasVideo(strategy);
    
    final meta = strategy.metadata ?? <String, dynamic>{};
    final voiceClips = TacticalVoiceClip.listFromMetadata(meta);
    final voiceTranscript = (meta['voiceTranscript'] ?? '').toString().trim();
    final parsedSteps = _parsePlaySteps(meta);
    final playSteps = parsedSteps.map((step) => step.kind.name.toUpperCase()).toList();
    final referenceUrl = (meta['referenceUrl'] ?? '').toString().trim();
    final created = strategy.createdAt.toLocal();
    final createdLabel = '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'STRATEGY DETAILS',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: outlineColor),
            onPressed: () => _shareStrategy(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    BasketballStrategy.categoryLabel(strategy.category).toUpperCase(),
                    style: const TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strategy.title,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk', height: 1.1),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: outlineColor.withOpacity(0.2),
                      child: const Icon(Icons.person, size: 14, color: outlineColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${strategy.createdByName} (${strategy.createdByRole})',
                      style: const TextStyle(color: outlineColor, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      createdLabel,
                      style: const TextStyle(color: outlineColor, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Action Row
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.grid_4x4_outlined,
                  label: 'TACTICAL LAB',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TacticalLabScreen(
                        initialPlayerMode: true,
                        initialSteps: parsedSteps.isNotEmpty ? parsedSteps : null,
                        initialVoiceClips: voiceClips.map((c) => c.toJson()).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          if (voiceClips.isNotEmpty) ...[
            CoachVoiceClipsPanel(
              clips: voiceClips,
              title: 'COACH VOICE',
              subtitle: 'Replay what the coach said while building this tactic.',
              accentColor: primaryColor,
              surfaceColor: surfaceHigh,
              outlineColor: outlineColor,
            ),
            const SizedBox(height: 32),
          ],

          // Breakdown Section
          _sectionHeader('STRATEGY BREAKDOWN'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceHigh.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: outlineColor.withOpacity(0.1)),
            ),
            child: Text(
              voiceTranscript.isNotEmpty ? voiceTranscript : strategy.sourceText,
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
            ),
          ),

          const SizedBox(height: 32),

          // Video Section
          if (hasVideo) ...[
            _sectionHeader('VIDEO PLAYBACK'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSocial ? Colors.red.withOpacity(0.2) : primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  if (strategy.thumbnailUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(ApiService.resolveMediaUrl(strategy.thumbnailUrl!), fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSocial ? Colors.red : primaryColor,
                      foregroundColor: isSocial ? Colors.white : Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _playVideo(context, resolved),
                    icon: Icon(isSocial ? Icons.open_in_new : Icons.play_arrow_rounded),
                    label: Text(
                      isSocial ? 'PLAY ON YOUTUBE / SOCIAL' : 'WATCH IN-APP VIDEO',
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                  if (isSocial)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'This is a social media link. Opening in external app for better experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: outlineColor.withOpacity(0.7), fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Play Steps Section
          if (playSteps.isNotEmpty) ...[
            _sectionHeader('KEY PLAYS / COACHING CUES'),
            const SizedBox(height: 12),
            ...List.generate(playSteps.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outlineColor.withOpacity(0.05)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}',
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        playSteps[index],
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
          ],

          // Tags Section
          if (strategy.tags.isNotEmpty) ...[
            _sectionHeader('STRATEGY TAGS'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: strategy.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: outlineColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('#$tag', style: const TextStyle(color: outlineColor, fontSize: 12, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Reference Section
          if (referenceUrl.isNotEmpty) ...[
            _sectionHeader('EXTERNAL REFERENCE'),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => launchUrl(Uri.parse(referenceUrl)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        referenceUrl,
                        style: const TextStyle(color: Colors.blue, fontSize: 13, decoration: TextDecoration.underline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _shareStrategy(BuildContext context) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 16),
              Text('Generating PDF Strategy Report...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final pdfBytes = await StrategyPdfGenerator.generate(strategy);
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Strategy_${strategy.title.replaceAll(' ', '_')}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (!context.mounted) return;
      await shareFiles(
        context,
        files: [XFile(file.path)],
        text: 'HoopStar Strategy: ${strategy.title}\nCategory: ${BasketballStrategy.categoryLabel(strategy.category)}',
        subject: 'Coaching Strategy: ${strategy.title}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap, Color? iconColor}) {
    return Material(
      color: surfaceHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: outlineColor.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor ?? primaryColor),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerDialog({required this.videoUrl});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _controller.play();
        _controller.setLooping(true);
      }).catchError((e) {
        setState(() => _error = e.toString());
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
            ],
          ),
          if (_error != null)
             Padding(padding: const EdgeInsets.all(20), child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
          else if (!_initialized)
            const Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFFFFD900)))
          else
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_controller),
                  VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Color(0xFFFFD900))),
                  Center(
                    child: IconButton(
                      icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, size: 50, color: Colors.white.withOpacity(0.5)),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
