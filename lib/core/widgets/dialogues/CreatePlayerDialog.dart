import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ballchart/features/staff/service/staff_service.dart';

class CreatePlayerDialog extends StatefulWidget {
  final Function(Map<String, String> player)? onPlayerCreated;
  final String? teamId;

  const CreatePlayerDialog({super.key, this.onPlayerCreated, this.teamId});

  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _AcademyTheme {
  static const Color primary = Color(0xFFFFDCA3);
  static const Color primaryContainer = Color(0xFFFDB927);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color outline = Color(0xFF9D8F79);
  static const Color tertiaryContainer = Color(0xFF14D7FF);
  static const Color error = Color(0xFFFFB4AB);
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  final StaffService _staffService = StaffService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;
  String? _profileImagePath;

  String _selectedPosition = 'PG';
  final List<String> _positions = ['PG', 'SG', 'SF', 'PF', 'C'];

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _createPlayer() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'All fields are required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? profileImageUrl;
      
      // Upload image if selected
      if (_profileImagePath != null) {
        profileImageUrl = await _staffService.uploadImage(File(_profileImagePath!));
      }

      await _staffService.createPlayer(
        name: name,
        email: email,
        password: password,
        teamId: widget.teamId,
        number: _numberController.text.trim(),
        position: _selectedPosition,
        profileImageUrl: profileImageUrl, // This is now nullable in the service
      );

      if (!mounted) return;
      Navigator.pop(context);

      widget.onPlayerCreated?.call({
        'name': name,
        'email': email,
        'tempPassword': password,
        'number': _numberController.text.trim(),
        'position': _selectedPosition,
        'profileImageUrl': profileImageUrl ?? '',
      });

      _showCredentialsDialog(context, name, email, password);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().toUpperCase().replaceAll('EXCEPTION: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AcademyTheme.surfaceDim,
      appBar: AppBar(
        backgroundColor: _AcademyTheme.surfaceDim,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _AcademyTheme.primaryContainer),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('ADD PLAYER', style: TextStyle(color: _AcademyTheme.primaryContainer, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildPhotoSection(),
            const SizedBox(height: 48),
            _buildInput('FULL NAME', 'e.g. Marcus Thompson', _nameController),
            const SizedBox(height: 32),
            _buildInput('LOGIN EMAIL', 'e.g. thompson.m@eliteacademy.pro', _emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 32),
            _buildPasswordInput(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildJerseyInput()),
                const SizedBox(width: 24),
                Expanded(child: _buildPositionDropdown()),
              ],
            ),
            const SizedBox(height: 40),
            _buildDirectiveCard(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Text(_errorMessage!, style: const TextStyle(color: _AcademyTheme.error, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _AcademyTheme.outline.withOpacity(0.2), style: BorderStyle.none),
                  color: _AcademyTheme.surfaceHigh,
                ),
                child: _profileImagePath != null
                    ? ClipOval(
                        child: Image.file(
                          File(_profileImagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.person, color: _AcademyTheme.outline, size: 32));
                          },
                        ),
                      )
                    : const Center(child: Icon(Icons.add_a_photo_rounded, color: _AcademyTheme.outline, size: 32)),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: _AcademyTheme.primaryContainer, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.black, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('UPLOAD PLAYER PROFILE IMAGE', style: TextStyle(color: _AcademyTheme.outline, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildJerseyInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('JERSEY NUMBER', style: TextStyle(color: _AcademyTheme.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        TextField(
          controller: _numberController,
          keyboardType: TextInputType.number,
          inputFormatters: const [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '07',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _AcademyTheme.surfaceHighest, width: 2)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _AcademyTheme.primaryContainer, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _AcademyTheme.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _AcademyTheme.surfaceHighest, width: 2)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _AcademyTheme.primaryContainer, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SECURED PASSWORD', style: TextStyle(color: _AcademyTheme.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '••••••••••••',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _AcademyTheme.surfaceHighest, width: 2)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _AcademyTheme.primaryContainer, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _AcademyTheme.outline, size: 20),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('POSITION', style: TextStyle(color: _AcademyTheme.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        DropdownButtonFormField<String>(
          value: _selectedPosition,
          dropdownColor: _AcademyTheme.surfaceContainer,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _AcademyTheme.surfaceHighest, width: 2)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _AcademyTheme.primaryContainer, width: 2)),
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          items: _positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (v) => setState(() => _selectedPosition = v!),
        ),
      ],
    );
  }

  Widget _buildDirectiveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _AcademyTheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _AcademyTheme.tertiaryContainer, size: 20),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACADEMY DIRECTIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                SizedBox(height: 6),
                Text(
                  'Initializing a new player creates a unique tactical profile and grants immediate access to the performance dashboard and court analytics.',
                  style: TextStyle(color: _AcademyTheme.outline, fontSize: 10, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, _AcademyTheme.surfaceDim.withOpacity(0.8), _AcademyTheme.surfaceDim],
        ),
      ),
      child: GestureDetector(
        onTap: _createPlayer,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFDB927), Color(0xFFFFDCA3)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _AcademyTheme.primaryContainer.withOpacity(0.2), blurRadius: 20)],
          ),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('INITIALIZE PLAYER', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
                SizedBox(width: 12),
                Icon(Icons.bolt_rounded, color: Colors.black, size: 20),
              ],
            ),
        ),
      ),
    );
  }

  void _showCredentialsDialog(BuildContext context, String name, String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _AcademyTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _AcademyTheme.primaryContainer.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: _AcademyTheme.tertiaryContainer, size: 56),
              const SizedBox(height: 16),
              const Text('PLAYER INITIALIZED', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
              const SizedBox(height: 24),
              _credentialBox('EMAIL', email),
              const SizedBox(height: 12),
              _credentialBox('TEMP PASSWORD', password),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: 'Email: $email\nPassword: $password'));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('COPIED TO CLIPBOARD')));
                      },
                      style: OutlinedButton.styleFrom(side: BorderSide(color: _AcademyTheme.outline.withOpacity(0.3))),
                      child: const Text('COPY', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: _AcademyTheme.primaryContainer, foregroundColor: Colors.black),
                      child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _credentialBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _AcademyTheme.surfaceDim, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _AcademyTheme.outline, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: _AcademyTheme.primaryContainer, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
