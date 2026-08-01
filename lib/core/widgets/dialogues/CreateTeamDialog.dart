import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ballchart/core/constants/colors.dart';
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/core/widgets/user_avatar.dart';

class CreateTeamDialog extends StatefulWidget {
  final FutureOr<void> Function(
    String name,
    String ageGroup,
    Color color,
    String? logoPath,
    String? coachId,
    String? assistantId,
  )? onTeamCreated;

  const CreateTeamDialog({super.key, this.onTeamCreated});

  @override
  State<CreateTeamDialog> createState() => _CreateTeamDialogState();
}

class _AcademyTheme {
  static const Color primary = Color(0xFFFFDCA3);
  static const Color primaryContainer = Color(0xFFFDB927);
  static const Color onPrimary = Color(0xFF422D00);
  static const Color background = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color outline = Color(0xFF9D8F79);
  static const Color outlineVariant = Color(0xFF504533);
}

class _CreateTeamDialogState extends State<CreateTeamDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedTier = 'U-14';
  Color _selectedColor = const Color(0xFFFDB927);
  String? _logoDataUri;
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedCoachId;
  String? _selectedAssistantId;
  bool _isSubmitting = false;

  final List<Map<String, String>> _tiers = [
    {'label': 'U-12', 'sub': 'Foundation'},
    {'label': 'U-14', 'sub': 'Development'},
    {'label': 'U-16', 'sub': 'Competitive'},
    {'label': 'U-19', 'sub': 'Professional'},
    {'label': 'OPEN', 'sub': 'Senior Squad'},
  ];

  final List<Color> _colors = [
    const Color(0xFFFDB927),
    const Color(0xFF14D7FF),
    const Color(0xFFFF4B4B),
    const Color(0xFF2ECC71),
    const Color(0xFF9B59B6),
    const Color(0xFFE67E22),
    const Color(0xFF34495E),
    const Color(0xFFE5E2E1),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _logoDataUri = 'data:image/png;base64,${base64Encode(bytes)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _AcademyTheme.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildIdentityBranding(),
              const SizedBox(height: 32),
              _buildSectionTitle('Operational Tier'),
              _buildOperationalTierGrid(),
              const SizedBox(height: 32),
              _buildSectionTitle('Team color'),
              _buildColorSignature(),
              const SizedBox(height: 32),
              _buildSectionTitle('Staff Assignment'),
              _buildStaffAssignment(),
              const SizedBox(height: 48),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SQUAD MANAGEMENT', style: TextStyle(color: _AcademyTheme.outline, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 4),
        const Text('Initialize New Team', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
      ],
    );
  }

  Widget _buildIdentityBranding() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _AcademyTheme.surfaceContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickLogo,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipPath(
                  clipper: ShieldClipper(),
                  child: Container(
                    width: 120,
                    height: 150,
                    color: _AcademyTheme.surfaceHigh,
                    child: _logoDataUri != null 
                      ? Image.memory(base64Decode(_logoDataUri!.split(',').last), fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.upload_file, color: _AcademyTheme.outline, size: 32),
                            const SizedBox(height: 8),
                            const Text('UPLOAD SHIELD', style: TextStyle(color: _AcademyTheme.outline, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: _AcademyTheme.primaryContainer, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Official academy insignias must be in high-resolution.', textAlign: TextAlign.center, style: TextStyle(color: _AcademyTheme.outlineVariant, fontSize: 10)),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SQUAD DESIGNATION', style: TextStyle(color: _AcademyTheme.primaryContainer, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'e.g. Golden Eagles Elite',
                  hintStyle: TextStyle(color: Colors.white12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _AcademyTheme.outlineVariant)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _AcademyTheme.primary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 4, height: 24, decoration: BoxDecoration(color: _AcademyTheme.primaryContainer, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
        ],
      ),
    );
  }

  Widget _buildOperationalTierGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _tierItem(_tiers[0])),
            const SizedBox(width: 8),
            Expanded(child: _tierItem(_tiers[1])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _tierItem(_tiers[2])),
            const SizedBox(width: 8),
            Expanded(child: _tierItem(_tiers[3])),
          ],
        ),
        const SizedBox(height: 8),
        _tierItem(_tiers[4], isFullWidth: true),
      ],
    );
  }

  Widget _tierItem(Map<String, String> tier, {bool isFullWidth = false}) {
    final isSelected = _selectedTier == tier['label'];
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier['label']!),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? _AcademyTheme.primaryContainer.withOpacity(0.1) : _AcademyTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? _AcademyTheme.primaryContainer : _AcademyTheme.outlineVariant.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Text(
              tier['label']!, 
              style: TextStyle(color: isSelected ? _AcademyTheme.primaryContainer : Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              tier['sub']!.toUpperCase(), 
              style: TextStyle(color: isSelected ? _AcademyTheme.primaryContainer.withOpacity(0.7) : _AcademyTheme.outline, fontSize: 8, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSignature() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _AcademyTheme.surfaceContainer, borderRadius: BorderRadius.circular(20)),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: _colors.map((color) {
          final isSelected = _selectedColor == color;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)] : [],
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStaffAssignment() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final coach = _selectedCoachId != null ? provider.getStaffById(_selectedCoachId) : null;
        final assistant = _selectedAssistantId != null ? provider.getStaffById(_selectedAssistantId) : null;

        return Column(
          children: [
            _staffSlot(
              'Head Coach',
              coach?.name,
              coach?.role ?? 'COACH',
              coach?.profilePic,
              () => _showStaffSelection(true),
            ),
            const SizedBox(height: 16),
            _staffSlot(
              'Assistant Coach',
              assistant?.name,
              assistant?.role ?? 'ASST COACH',
              assistant?.profilePic,
              () => _showStaffSelection(false),
            ),
          ],
        );
      },
    );
  }

  void _showStaffSelection(bool isCoach) {
    final provider = context.read<AcademyProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: _AcademyTheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _AcademyTheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(isCoach ? 'SELECT HEAD COACH' : 'SELECT ASSISTANT COACH', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: provider.academy.staff.length,
                itemBuilder: (context, index) {
                  final s = provider.academy.staff[index];
                  return ListTile(
                    onTap: () {
                      setState(() {
                        if (isCoach) _selectedCoachId = s.id;
                        else _selectedAssistantId = s.id;
                      });
                      Navigator.pop(context);
                    },
                    selected: isCoach ? _selectedCoachId == s.id : _selectedAssistantId == s.id,
                    selectedTileColor: _AcademyTheme.primaryContainer.withOpacity(0.1),
                    leading: UserAvatar(
                      name: s.name,
                      imageUrl: s.profilePic,
                      size: 40,
                      usePersonIconFallback: true,
                      accentColor: _AcademyTheme.primaryContainer,
                      backgroundColor: _AcademyTheme.surfaceHigh,
                    ),
                    title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(s.role.toUpperCase(), style: const TextStyle(color: _AcademyTheme.outline, fontSize: 10)),
                    trailing: const Icon(Icons.add_circle_outline_rounded, color: _AcademyTheme.primaryContainer),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _staffSlot(String label, String? name, String? role, String? img, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _AcademyTheme.surfaceContainer, borderRadius: BorderRadius.circular(16), border: Border.all(color: _AcademyTheme.outlineVariant.withOpacity(0.3))),
            child: Row(
              children: [
                if (name != null)
                  UserAvatar(
                    name: name,
                    imageUrl: img,
                    size: 40,
                    usePersonIconFallback: true,
                    accentColor: _AcademyTheme.primaryContainer,
                    backgroundColor: _AcademyTheme.surfaceHigh,
                  )
                else
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: _AcademyTheme.surfaceHigh, shape: BoxShape.circle), child: const Icon(Icons.person_add, color: _AcademyTheme.outline)),
                const SizedBox(width: 12),
                Expanded(
                  child: name != null 
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(role!.toUpperCase(), style: const TextStyle(color: _AcademyTheme.outline, fontSize: 10))])
                    : Text('Assign ${label.toLowerCase()}...', style: const TextStyle(color: _AcademyTheme.outline, fontStyle: FontStyle.italic, fontSize: 13)),
                ),
                const Icon(Icons.search, color: _AcademyTheme.outline, size: 20),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: _AcademyTheme.background,
              child: Text(label.toUpperCase(), style: const TextStyle(color: _AcademyTheme.outline, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (_nameController.text.isEmpty || widget.onTeamCreated == null) return;
                    setState(() => _isSubmitting = true);
                    try {
                      await widget.onTeamCreated!(
                        _nameController.text,
                        _selectedTier,
                        _selectedColor,
                        _logoDataUri,
                        _selectedCoachId,
                        _selectedAssistantId,
                      );
                      if (mounted) Navigator.pop(context, true);
                    } catch (_) {
                      // Host/dialog caller handles error feedback.
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedColor,
              foregroundColor: _selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('INITIALIZE SQUAD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('DISCARD DRAFT', style: TextStyle(color: _AcademyTheme.outline, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ),
      ],
    );
  }
}

class ShieldClipper extends CustomClipper<Path> {
  @override
  Path getSelectionPath(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.15);
    path.lineTo(size.width, size.height * 0.7);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(0, size.height * 0.7);
    path.lineTo(0, size.height * 0.15);
    path.close();
    return path;
  }
  @override
  Path getClip(Size size) => getSelectionPath(size);
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

extension WidgetExt on Widget {
  Widget toExpandedIf(bool condition) => condition ? SizedBox(width: double.infinity, child: this) : this;
}
