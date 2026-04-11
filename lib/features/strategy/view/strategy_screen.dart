import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/strategy_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/dialogues/CreateStrategyDialog.dart';
import '../../../core/widgets/dialogues/strategy_creation_options_sheet.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../viewmodel/strategy_viewmodel.dart';

class StrategyScreen extends StatefulWidget {
  const StrategyScreen({super.key});

  @override
  State<StrategyScreen> createState() => _StrategyScreenState();
}

enum _StrategyMediaFilter { all, video, nonVideo }

class _StrategyScreenState extends State<StrategyScreen> {
  _StrategyMediaFilter _mediaFilter = _StrategyMediaFilter.all;
  StrategyViewmodel? _strategyViewmodel;

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF201F1F);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithRetry();
    });
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final vm = context.read<StrategyViewmodel>();
        _strategyViewmodel = vm;
        await vm.loadStrategies();
        vm.startLiveSync(); // Start real-time updates
        
        final profileVm = context.read<ProfileViewmodel>();
        if (profileVm.user == null) {
          await profileVm.loadProfile(forceRefresh: true);
        }
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load strategies: ${e.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _loadDataWithRetry(),
                ),
              ),
            );
          }
        } else {
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));
        }
      }
    }
  }

  @override
  void dispose() {
    _strategyViewmodel?.stopLiveSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Consumer<StrategyViewmodel>(
            builder: (context, vm, _) {
              // Show loading state
              if (vm.isLoading && vm.strategies.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      SizedBox(height: 16),
                      Text('Loading Strategies...', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                );
              }

              // Show error state
              if (vm.errorMessage != null && vm.strategies.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Strategies',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vm.errorMessage!,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _loadDataWithRetry(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildMediaFilterRow(),
                  const SizedBox(height: 24),
                  const Text('TACTICAL REELS', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  _buildTacticalReels(vm),
                  const SizedBox(height: 32),
                  _buildFormationAnalytics(),
                  const SizedBox(height: 32),
                  const Text('ACTIVE PLAYBOOK', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                  const SizedBox(height: 16),
                  ..._buildPlaybookItems(vm),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ProfileViewmodel>(
      builder: (context, profileVm, _) {
        final canCreate = profileVm.user?.role == 'admin' || 
                         profileVm.user?.role == 'head_coach' || 
                         profileVm.user?.role == 'coach';
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PLAYBOOK INTELLIGENCE', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                SizedBox(height: 4),
                Text('TACTICAL STRATEGY', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
              ],
            ),
            if (canCreate)
              GestureDetector(
                onTap: () => _openStrategyCreationFlow(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.black, size: 24),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _strategyHasVideo(StrategyModel s) => s.videoUrl.trim().isNotEmpty;

  List<StrategyModel> _visibleStrategies(StrategyViewmodel vm) {
    final list = vm.strategies;
    switch (_mediaFilter) {
      case _StrategyMediaFilter.all:
        return list;
      case _StrategyMediaFilter.video:
        return list.where(_strategyHasVideo).toList();
      case _StrategyMediaFilter.nonVideo:
        return list.where((s) => !_strategyHasVideo(s)).toList();
    }
  }

  Widget _buildMediaFilterRow() {
    Widget chip(String label, _StrategyMediaFilter value) {
      final selected = _mediaFilter == value;
      return GestureDetector(
        onTap: () => setState(() => _mediaFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primaryColor.withOpacity(0.2) : surfaceHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? primaryColor : outlineColor.withOpacity(0.25)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? primaryColor : outlineColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('ALL', _StrategyMediaFilter.all),
        const SizedBox(width: 8),
        chip('VIDEO', _StrategyMediaFilter.video),
        const SizedBox(width: 8),
        chip('NO VIDEO', _StrategyMediaFilter.nonVideo),
      ],
    );
  }

  Widget _buildTacticalReels(StrategyViewmodel vm) {
    if (vm.isLoading) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: primaryColor)));
    final strategies = _visibleStrategies(vm);
    if (strategies.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(24), border: Border.all(color: outlineColor.withOpacity(0.1), style: BorderStyle.solid)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, color: outlineColor, size: 32),
            const SizedBox(height: 12),
            Text(
              vm.strategies.isEmpty ? 'NO REELS UPLOADED' : 'NO STRATEGIES FOR THIS FILTER',
              style: const TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: strategies.length,
        itemBuilder: (context, index) => _reelCard(strategies[index]),
      ),
    );
  }

  Widget _reelCard(StrategyModel strategy) {
    final thumb = ApiService.resolveMediaUrl(strategy.thumbnailUrl);
    final hasPlayableVideo = _strategyHasVideo(strategy);
    final resolvedVideo = ApiService.resolveMediaUrl(strategy.videoUrl);
    final canPlayNetwork = resolvedVideo.startsWith('http://') || resolvedVideo.startsWith('https://');

    return GestureDetector(
      onTap: () {
        if (hasPlayableVideo && canPlayNetwork) {
          _playVideo(context, resolvedVideo);
        } else {
          _showStrategyDetailSheet(strategy, highlightVideo: false);
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [surfaceHigh, surfaceHigh.withOpacity(0.85), bgColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: thumb.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(thumb),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.45), BlendMode.darken),
                )
              : null,
        ),
        child: Stack(
          children: [
            if (hasPlayableVideo)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(8)),
                  child: const Text('VIDEO', style: TextStyle(color: primaryColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strategy.title.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(strategy.category.toUpperCase(), style: const TextStyle(color: primaryColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
            if (hasPlayableVideo && canPlayNetwork)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: primaryColor, size: 24),
                ),
              )
            else if (!hasPlayableVideo)
              Center(
                child: Icon(Icons.movie_creation_outlined, color: outlineColor.withOpacity(0.6), size: 36),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationAnalytics() {
    return Row(
      children: [
        Expanded(child: _analyticsCard('FORMATION ENGAGEMENT', '88%', Icons.insights, const Color(0xFF28D8FF))),
        const SizedBox(width: 16),
        Expanded(child: _analyticsCard('DRILL COMPLETION', '94%', Icons.check_circle, primaryColor)),
      ],
    );
  }

  Widget _analyticsCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(val, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  List<Widget> _buildPlaybookItems(StrategyViewmodel vm) {
    final items = _visibleStrategies(vm);
    if (items.isEmpty) {
      return [
        Text(
          vm.strategies.isEmpty ? 'No plays in playbook.' : 'Nothing matches this filter.',
          style: const TextStyle(color: outlineColor),
        ),
      ];
    }
    return items.map((s) => _playbookItem(s)).toList();
  }

  Widget _playbookItem(StrategyModel s) {
    final hasVideo = _strategyHasVideo(s);
    final subtitle = '${s.category.toUpperCase()} • ${s.sourceType.toUpperCase()}'
        '${hasVideo ? ' • VIDEO' : ''}';

    return GestureDetector(
      onTap: () => _showStrategyDetailSheet(s, highlightVideo: hasVideo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B1B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasVideo ? primaryColor.withOpacity(0.35) : outlineColor.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(10)),
                    child: Icon(hasVideo ? Icons.videocam_outlined : Icons.description, color: hasVideo ? primaryColor : outlineColor, size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(hasVideo ? Icons.play_circle_outline : Icons.chevron_right, color: outlineColor, size: 22),
          ],
        ),
      ),
    );
  }

  void _showStrategyDetailSheet(StrategyModel s, {required bool highlightVideo}) {
    final resolved = ApiService.resolveMediaUrl(s.videoUrl);
    final canPlay = resolved.startsWith('http://') || resolved.startsWith('https://');

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaceHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: outlineColor.withOpacity(0.35), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(s.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
                const SizedBox(height: 8),
                Text('${s.category.toUpperCase()} • ${s.sourceType.toUpperCase()}', style: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 16),
                Text(s.sourceText, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.45)),
                if (canPlay) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _playVideo(context, resolved);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('PLAY STRATEGY VIDEO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ),
                ] else if (highlightVideo) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Add a valid HTTPS video URL when creating or editing this strategy to enable playback.',
                    style: TextStyle(color: outlineColor.withOpacity(0.9), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openStrategyCreationFlow(BuildContext context) async {
    final vm = context.read<StrategyViewmodel>();
    final entry = await showStrategyCreationOptionsSheet(context);
    if (!context.mounted || entry == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => CreateStrategyDialog(
        entry: entry,
        onStrategyCreated:
            (title, description, category, sourceTypeForApi, plays, imagePath, videoUrl, tags, referenceUrl) async {
          try {
            await vm.createStrategy(
                  title: title,
                  category: category,
                  sourceType: sourceTypeForApi,
                  sourceText: description,
                  videoUrl: (videoUrl ?? '').trim().isEmpty ? null : videoUrl!.trim(),
                  tags: tags,
                  metadata: {
                    'playSteps': plays,
                    'revisionState': 'draft',
                    'creationEntry': entry.name,
                    if (referenceUrl != null && referenceUrl.trim().isNotEmpty) 'referenceUrl': referenceUrl.trim(),
                    if (imagePath != null && imagePath.isNotEmpty) 'localDiagramPath': imagePath,
                  },
                );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Strategy created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create strategy: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _playVideo(BuildContext context, String videoUrl) async {
    showDialog(context: context, builder: (_) => _VideoPlayerDialog(videoUrl: videoUrl));
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerDialog({required this.videoUrl});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }
      
      final uri = Uri.parse(widget.videoUrl);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        throw Exception('Invalid video URL format');
      }
      
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load video: ${e.toString().replaceAll('Exception: ', '')}';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF020617),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Strategy Video',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            else if (_controller != null)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio == 0
                    ? (16 / 9)
                    : _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
          ],
        ),
      ),
    );
  }
}
