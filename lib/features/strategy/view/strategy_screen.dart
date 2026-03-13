import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/strategy_model.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../viewmodel/strategy_viewmodel.dart';

class StrategyScreen extends StatefulWidget {
  const StrategyScreen({super.key});

  @override
  State<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends State<StrategyScreen> {
  String _filter = 'all';
  StrategyViewmodel? _strategyViewmodel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<StrategyViewmodel>();
      _strategyViewmodel = vm;
      vm.loadStrategies();
      vm.startLiveSync();
      final profileVm = context.read<ProfileViewmodel>();
      if (profileVm.user == null) {
        profileVm.loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _strategyViewmodel?.stopLiveSync();
    super.dispose();
  }

  bool _canCreateStrategy(String? role) {
    return role == 'admin' ||
        role == 'head_coach' ||
        role == 'coach' ||
        role == 'assistant_coach';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  List<StrategyModel> _filtered(List<StrategyModel> list) {
    if (_filter == 'all') return list;
    return list.where((item) => item.category == _filter).toList();
  }

  Future<void> _showCreateStrategyDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final sourceCtrl = TextEditingController();
    final videoCtrl = TextEditingController();
    String category = 'general';
    String sourceType = 'text';
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Strategy Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Title'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: _inputDecoration('Category'),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('General')),
                        DropdownMenuItem(value: 'offense', child: Text('Offense')),
                        DropdownMenuItem(value: 'defense', child: Text('Defense')),
                        DropdownMenuItem(value: 'drills', child: Text('Drills')),
                      ],
                      onChanged: (v) => setSheetState(() => category = v ?? 'general'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: sourceType,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: _inputDecoration('Source Type'),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('Text Input')),
                        DropdownMenuItem(value: 'voice', child: Text('Voice Transcript')),
                      ],
                      onChanged: (v) => setSheetState(() => sourceType = v ?? 'text'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: sourceCtrl,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: _inputDecoration(
                        sourceType == 'voice'
                            ? 'Voice notes / transcript'
                            : 'Strategy details',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: videoCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Video URL (http/https)'),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: submitting
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                final sourceText = sourceCtrl.text.trim();
                                final videoUrl = videoCtrl.text.trim();
                                if (title.isEmpty || videoUrl.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Title and video URL are required'),
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() => submitting = true);
                                try {
                                  await context.read<StrategyViewmodel>().createStrategy(
                                        title: title,
                                        category: category,
                                        sourceType: sourceType,
                                        sourceText: sourceText,
                                        videoUrl: videoUrl,
                                      );
                                  if (context.mounted) {
                                    Navigator.pop(sheetCtx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Strategy published for players'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll('Exception: ', ''),
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setSheetState(() => submitting = false);
                                  }
                                }
                              },
                        icon: submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.publish),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        label: const Text('Publish Strategy'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _playVideo(BuildContext context, String videoUrl) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VideoPlayerDialog(videoUrl: videoUrl),
    );
  }

  Widget _chip(String id, String label) {
    final selected = _filter == id;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _filter = id),
      selectedColor: AppColors.yellow,
      backgroundColor: const Color(0xFF1E293B),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.w600,
      ),
      side: const BorderSide(color: Colors.white10),
    );
  }

  Widget _strategyCard(StrategyModel strategy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strategy.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  strategy.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${strategy.createdByName} • ${strategy.createdByRole.replaceAll('_', ' ')} • ${_timeAgo(strategy.createdAt)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          if (strategy.sourceText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              strategy.sourceText,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _playVideo(context, strategy.videoUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Watch Video'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Consumer<ProfileViewmodel>(
            builder: (context, profileVm, _) {
              final user = profileVm.user;
              final canCreate = _canCreateStrategy(user?.role);
              return Consumer<StrategyViewmodel>(
                builder: (context, vm, _) {
                  final strategies = _filtered(vm.strategies);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Strategy Videos',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Live tactical videos for players',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: vm.isLoading ? null : () => vm.loadStrategies(),
                            icon: const Icon(Icons.refresh, color: Colors.white70),
                          ),
                          if (canCreate)
                            CircleAvatar(
                              backgroundColor: AppColors.yellow,
                              child: IconButton(
                                onPressed: () => _showCreateStrategyDialog(context),
                                icon: const Icon(Icons.add, color: Colors.black),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip('all', 'All'),
                          _chip('offense', 'Offense'),
                          _chip('defense', 'Defense'),
                          _chip('drills', 'Drills'),
                          _chip('general', 'General'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: vm.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : strategies.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No strategy videos yet.',
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: strategies.length,
                                    itemBuilder: (context, index) =>
                                        _strategyCard(strategies[index]),
                                  ),
                      ),
                    ],
                  );
                },
              );
            },
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
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to play this video URL';
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
