import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'strategy_creation_entry.dart';
import '../../../features/tactics/view/tactical_lab_screen.dart';
import '../../tactical/tactical_entities.dart';
import '../../tactical/voice_command_parser.dart';
import '../../tactical/tactical_ai_suggestions.dart';
import '../../models/tactical/tactical_schema.dart';

class CreateStrategyDialog extends StatefulWidget {
  final StrategyCreationEntry entry;

  /// [categoryId] is UI bucket (offense/defense/transition/special).
  /// [sourceTypeForApi] is normalized for the API: `video`, `diagram`, or `text`.
  final Future<void> Function(
    String title,
    String description,
    String categoryId,
    String sourceTypeForApi,
    List<String> plays,
    String? imagePath,
    String? videoUrl,
    List<String> tags,
    String? referenceUrl,
  ) onStrategyCreated;

  const CreateStrategyDialog({
    super.key,
    required this.onStrategyCreated,
    this.entry = StrategyCreationEntry.fullPlaybook,
  });

  @override
  State<CreateStrategyDialog> createState() => _CreateStrategyDialogState();
}

class _CreateStrategyDialogState extends State<CreateStrategyDialog> {
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color outlineColor = Color(0xFF9D8F79);

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _referenceUrlController = TextEditingController();
  final _playController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedType = 'offense';
  List<String> _plays = [];
  List<String> _tags = [];
  File? _strategyImage;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _strategyTypes = [
    {'id': 'offense', 'name': 'OFFENSE', 'icon': Icons.sports_basketball, 'color': primaryColor},
    {'id': 'defense', 'name': 'DEFENSE', 'icon': Icons.shield, 'color': Colors.red},
    {'id': 'transition', 'name': 'TRANSITION', 'icon': Icons.swap_horiz, 'color': Colors.blue},
    {'id': 'special', 'name': 'SPECIAL', 'icon': Icons.star, 'color': Colors.purple},
  ];

  final List<String> _commonPlays = [
    'Pick and Roll',
    'Isolation',
    'Fast Break',
    'Zone Defense',
    'Man to Man',
    'Press Break',
    'Post Up',
    'Three Point Play',
    'Drive and Kick',
    'High Post',
  ];

  final List<String> _suggestedTags = [
    'transition',
    'half court',
    'zone',
    'press',
    'ATO',
    'BLOB',
    'SLOB',
    'shooting',
  ];

  bool _looksLikeHttpUrl(String value) {
    final t = value.trim();
    if (t.isEmpty) return false;
    final uri = Uri.tryParse(t);
    return uri != null && uri.hasAbsolutePath && (uri.isScheme('http') || uri.isScheme('https'));
  }

  bool _isLikelyUnsupportedVideoUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('facebook.com') ||
        host.contains('instagram.com') ||
        host.contains('tiktok.com');
  }

  String _mapCategoryForApi(String id) {
    switch (id) {
      case 'offense':
        return 'offense';
      case 'defense':
        return 'defense';
      case 'transition':
        return 'general';
      case 'special':
        return 'drills';
      default:
        return 'general';
    }
  }

  String _computeSourceTypeForApi() {
    final v = _videoUrlController.text.trim();
    final hasVideo = _looksLikeHttpUrl(v);
    switch (widget.entry) {
      case StrategyCreationEntry.videoFirst:
        return 'video';
      case StrategyCreationEntry.diagramFirst:
        if (_strategyImage != null) return 'diagram';
        return hasVideo ? 'video' : 'text';
      case StrategyCreationEntry.textOnly:
        return 'text';
      case StrategyCreationEntry.linkLibrary:
        return hasVideo ? 'video' : 'text';
      case StrategyCreationEntry.fullPlaybook:
        if (hasVideo) return 'video';
        if (_strategyImage != null) return 'diagram';
        return 'text';
    }
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final video = _videoUrlController.text.trim();
    final reference = _referenceUrlController.text.trim();

    String? error;
    if (title.isEmpty || description.isEmpty) {
      error = 'Add a strategy name and description.';
    } else if (widget.entry == StrategyCreationEntry.videoFirst) {
      if (!_looksLikeHttpUrl(video)) {
        error = 'Add a valid https video or stream URL for this entry type.';
      } else if (_plays.isEmpty) {
        error = 'Add at least one key play or coaching cue.';
      }
    } else if (widget.entry == StrategyCreationEntry.diagramFirst) {
      if (_strategyImage == null && _plays.isEmpty) {
        error = 'Add a diagram image or at least one key play.';
      }
    } else if (widget.entry == StrategyCreationEntry.textOnly) {
      if (_plays.isEmpty) {
        error = 'Add at least one key play or coaching cue.';
      }
    } else if (widget.entry == StrategyCreationEntry.linkLibrary) {
      if (!_looksLikeHttpUrl(reference)) {
        error = 'Add a valid https link (Hudl, article, or doc).';
      }
    } else {
      // fullPlaybook
      if (_plays.isEmpty) {
        error = 'Add at least one key play.';
      }
    }

    if (error == null && video.isNotEmpty && !_looksLikeHttpUrl(video)) {
      error = 'Video URL must be a valid http(s) link.';
    }
    // We now allow social page URLs as they can be launched in the external YouTube app or browser.
    // if (error == null && video.isNotEmpty && _isLikelyUnsupportedVideoUrl(video)) {
    //   error = 'Please use a direct MP4/HLS stream URL. Social page URLs (YouTube/Facebook/Instagram/TikTok) are not playable in-app.';
    // }
    if (error == null && reference.isNotEmpty && !_looksLikeHttpUrl(reference)) {
      error = 'Reference link must be a valid http(s) URL.';
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final headerHint = widget.entry == StrategyCreationEntry.fullPlaybook
        ? 'Design your winning playbook'
        : widget.entry.subtitle;

    return Dialog(
      backgroundColor: surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceHigh,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.entry.icon, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CREATE STRATEGY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                        Text(
                          headerHint,
                          style: TextStyle(color: outlineColor.withOpacity(0.95), fontSize: 11, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: outlineColor),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('1', 'STRATEGY TYPE'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _strategyTypes.length,
                        itemBuilder: (context, index) {
                          final type = _strategyTypes[index];
                          final isSelected = _selectedType == type['id'];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedType = type['id']),
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? type['color'].withOpacity(0.2) : surfaceHigh,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? type['color'] : outlineColor.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(type['icon'], color: isSelected ? type['color'] : outlineColor, size: 24),
                                  const SizedBox(height: 8),
                                  Text(
                                    type['name'],
                                    style: TextStyle(
                                      color: isSelected ? type['color'] : outlineColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInputField('STRATEGY NAME', _titleController, 'e.g. Horns flare vs zone'),
                    const SizedBox(height: 16),
                    _buildInputField('DESCRIPTION', _descriptionController, 'Coaching points, reads, counters…', maxLines: 3),
                    const SizedBox(height: 24),

                    if (widget.entry == StrategyCreationEntry.diagramFirst ||
                        widget.entry == StrategyCreationEntry.fullPlaybook ||
                        widget.entry == StrategyCreationEntry.videoFirst ||
                        widget.entry == StrategyCreationEntry.linkLibrary) ...[
                      _sectionTitle('2', 'DIAGRAM (OPTIONAL)'),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: surfaceHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: outlineColor.withOpacity(0.2)),
                          ),
                          child: _strategyImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(_strategyImage!, fit: BoxFit.cover, width: double.infinity),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, color: outlineColor, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.entry == StrategyCreationEntry.diagramFirst
                                        ? 'Tap to add whiteboard / screenshot'
                                        : 'Tap to add diagram (optional)',
                                      style: TextStyle(color: outlineColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (widget.entry != StrategyCreationEntry.textOnly) ...[
                      _sectionTitle('3', 'VIDEO / STREAM (OPTIONAL)'),
                      const SizedBox(height: 8),
                      Text(
                        'Direct .mp4, HLS, or page URLs your player can open. YouTube often needs embed or share links your backend accepts.',
                        style: TextStyle(color: outlineColor.withOpacity(0.85), fontSize: 10, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        'VIDEO URL',
                        _videoUrlController,
                        'https://…',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _urlChip('YouTube', 'https://www.youtube.com/watch?v='),
                          _urlChip('Storage', 'https://'),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    _sectionTitle('4', 'REFERENCE LINK (OPTIONAL)'),
                    const SizedBox(height: 8),
                    Text(
                      'Hudl, Google Doc, or long-form scouting — separate from the clip above.',
                      style: TextStyle(color: outlineColor.withOpacity(0.85), fontSize: 10, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField('REFERENCE URL', _referenceUrlController, 'https://…'),
                    const SizedBox(height: 24),

                    _sectionTitle('5', 'KEY PLAYS / CUES'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_plays.length} items',
                          style: TextStyle(color: outlineColor, fontSize: 10),
                        ),
                        TextButton.icon(
                          onPressed: _openTacticalLab,
                          icon: const Icon(Icons.grid_4x4, size: 14, color: primaryColor),
                          label: const Text('DESIGN IN LAB', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _playController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Add a play or cue…',
                              hintStyle: TextStyle(color: outlineColor.withOpacity(0.5)),
                              filled: true,
                              fillColor: surfaceHigh,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: outlineColor.withOpacity(0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: outlineColor.withOpacity(0.2)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _addPlay,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonPlays.map((play) {
                        return GestureDetector(
                          onTap: () {
                            _playController.text = play;
                            _addPlay();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: surfaceHigh,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: outlineColor.withOpacity(0.2)),
                            ),
                            child: Text(play, style: TextStyle(color: outlineColor, fontSize: 10)),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_plays.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ..._plays.asMap().entries.map((entry) {
                        final index = entry.key;
                        final play = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: surfaceHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: outlineColor.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${index + 1}. $play',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _plays.removeAt(index)),
                                child: Icon(Icons.remove_circle, color: Colors.red.withOpacity(0.7), size: 20),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),
                    _sectionTitle('6', 'TAGS (OPTIONAL)'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (_) => _addTag(),
                            decoration: InputDecoration(
                              hintText: 'Add tag…',
                              hintStyle: TextStyle(color: outlineColor.withOpacity(0.5)),
                              filled: true,
                              fillColor: surfaceHigh,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: outlineColor.withOpacity(0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: outlineColor.withOpacity(0.2)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _addTag,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: surfaceHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: outlineColor.withOpacity(0.3)),
                            ),
                            child: Icon(Icons.label_outline, color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestedTags.map((t) {
                        return GestureDetector(
                          onTap: () {
                            _tagController.text = t;
                            _addTag();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: surfaceHigh,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: outlineColor.withOpacity(0.2)),
                            ),
                            child: Text(t, style: TextStyle(color: outlineColor, fontSize: 10)),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.asMap().entries.map((e) {
                          final i = e.key;
                          final tag = e.value;
                          return InputChip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(() => _tags.removeAt(i)),
                            backgroundColor: surfaceHigh,
                            side: BorderSide(color: outlineColor.withOpacity(0.2)),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceHigh,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          color: outlineColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createStrategy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text(
                              'CREATE STRATEGY',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String num, String label) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            num,
            style: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _urlChip(String label, String prefix) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        setState(() {
          if (_videoUrlController.text.trim().isEmpty) {
            _videoUrlController.text = prefix;
          }
        });
      },
      backgroundColor: surfaceHigh,
      side: BorderSide(color: outlineColor.withOpacity(0.25)),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: outlineColor.withOpacity(0.5)),
            filled: true,
            fillColor: surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineColor.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  void _addPlay() {
    final play = _playController.text.trim();
    if (play.isNotEmpty && !_plays.contains(play)) {
      setState(() {
        _plays.add(play);
        _playController.clear();
      });
    }
  }

  void _addTag() {
    final t = _tagController.text.trim().toLowerCase();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() {
        _tags.add(t);
        _tagController.clear();
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _strategyImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createStrategy() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final videoRaw = _videoUrlController.text.trim();
      final refRaw = _referenceUrlController.text.trim();
      await widget.onStrategyCreated(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _mapCategoryForApi(_selectedType),
        _computeSourceTypeForApi(),
        List<String>.from(_plays),
        _strategyImage?.path,
        videoRaw.isEmpty ? null : videoRaw,
        List<String>.from(_tags),
        refRaw.isEmpty ? null : refRaw,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create strategy: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openTacticalLab() async {
    final result = await Navigator.of(context).push<List<PlayStep>>(
      MaterialPageRoute(
        builder: (_) => const TacticalLabScreen(returnOnSave: true),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        for (final step in result) {
          // Convert step to a readable command that our parser understands
          String? cmd;
          if (step.kind == PlayStepKind.pass) {
            cmd = 'P${step.actorSlot} pass to P${step.targetSlot}';
          } else if (step.kind == PlayStepKind.handoff) {
            cmd = 'P${step.actorSlot} handoff to P${step.targetSlot}';
          } else if (step.kind == PlayStepKind.shoot) {
            cmd = 'P${step.actorSlot} shoot';
          } else if (step.kind == PlayStepKind.cut && step.toNorm != null) {
            cmd = 'P${step.actorSlot} move to target'; // Simplified for now
          }

          if (cmd != null && !_plays.contains(cmd)) {
            _plays.add(cmd);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _referenceUrlController.dispose();
    _playController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}
