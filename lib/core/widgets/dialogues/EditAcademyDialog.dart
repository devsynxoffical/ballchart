import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';

class EditAcademyDialog extends StatefulWidget {
  final String currentName;
  final String? currentLogo;
  final String currentOwner;
  final String currentEmail;

  const EditAcademyDialog({
    super.key,
    required this.currentName,
    this.currentLogo,
    required this.currentOwner,
    required this.currentEmail,
  });

  @override
  State<EditAcademyDialog> createState() => _EditAcademyDialogState();
}

class _AcademyTheme {
  static const Color primaryContainer = Color(0xFFFDB927);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color outline = Color(0xFF9D8F79);
}

class _EditAcademyDialogState extends State<EditAcademyDialog> {
  late TextEditingController _nameController;
  late TextEditingController _ownerController;
  late TextEditingController _emailController;
  bool _isLoading = false;
  String? _logoDataUri;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _ownerController = TextEditingController(text: widget.currentOwner);
    _emailController = TextEditingController(text: widget.currentEmail);
    _logoDataUri = widget.currentLogo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateAcademy() async {
    final name = _nameController.text.trim();
    final owner = _ownerController.text.trim();
    final email = _emailController.text.trim();
    
    if (name.isEmpty || owner.isEmpty || email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final provider = context.read<AcademyProvider>();
      await provider.updateAcademyProfileInBackend(
        academyName: name,
        ownerName: owner,
        ownerEmail: email,
        logoUrl: _logoDataUri,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _AcademyTheme.surfaceDim,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACADEMY PROFILE',
                style: TextStyle(
                  color: _AcademyTheme.primaryContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
            _buildLogoPicker(),
            const SizedBox(height: 32),
            _buildField('OFFICIAL NAME', _nameController),
              const SizedBox(height: 24),
              _buildField('DIRECTOR NAME', _ownerController),
              const SizedBox(height: 24),
              _buildField('CONTACT EMAIL', _emailController),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateAcademy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AcademyTheme.primaryContainer,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Center(
                  child: Text(
                    'CANCEL',
                    style: TextStyle(color: _AcademyTheme.outline, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickLogo,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _AcademyTheme.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: _AcademyTheme.primaryContainer.withOpacity(0.5), width: 2),
              ),
              child: ClipOval(
                child: _logoDataUri != null
                    ? (_logoDataUri!.startsWith('data:')
                        ? Image.memory(base64Decode(_logoDataUri!.split(',')[1]), fit: BoxFit.cover)
                        : Image.network(_logoDataUri!, fit: BoxFit.cover))
                    : Image.asset('basketball_icon.png', fit: BoxFit.cover),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: _AcademyTheme.primaryContainer, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _logoDataUri = 'data:image/png;base64,${base64Encode(bytes)}';
    });
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _AcademyTheme.outline,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _AcademyTheme.primaryContainer),
            ),
          ),
        ),
      ],
    );
  }
}
