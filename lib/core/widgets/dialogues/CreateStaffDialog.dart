import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:ballchart/core/constants/colors.dart';
import 'package:ballchart/features/staff/service/staff_service.dart';

class CreateStaffDialog extends StatefulWidget {
  final String initialRole;
  final FutureOr<void> Function(Map<String, dynamic> staff)? onStaffCreated;

  const CreateStaffDialog({
    super.key,
    required this.initialRole,
    this.onStaffCreated,
  });

  @override
  State<CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends State<CreateStaffDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _customRoleController = TextEditingController();

  final StaffService _staffService = StaffService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _profileImagePath;

  late String _selectedRole;
  final List<String> _roles = ['Coach', 'Assistant Coach', 'Custom'];
  
  final Map<String, bool> _permissions = {
    'createPlayer': true,
    'updatePlayer': true,
    'deletePlayer': false,
    'createTeam': true,
    'manageStaff': false,
    'createBattle': false,
    'manageBattle': false,
    'createStrategy': false,
    'manageStrategy': false,
  };

  static const Color primaryGold = Color(0xFFFFDCA3);
  static const Color primaryContainer = Color(0xFFFDB927);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color outline = Color(0xFF9D8F79);

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole.contains('Assistant') ? 'Assistant Coach' : (widget.initialRole.contains('Custom') ? 'Custom' : 'Coach');
    _applyRoleDefaults(_selectedRole);
  }

  void _applyRoleDefaults(String role) {
    if (role == 'Coach') {
      _permissions['createPlayer'] = true;
      _permissions['updatePlayer'] = true;
      _permissions['deletePlayer'] = false;
      _permissions['createTeam'] = true;
      _permissions['manageStaff'] = false;
      _permissions['createBattle'] = true;
      _permissions['manageBattle'] = true;
      _permissions['createStrategy'] = true;
      _permissions['manageStrategy'] = true;
    } else if (role == 'Assistant Coach') {
      _permissions['createPlayer'] = true;
      _permissions['updatePlayer'] = false;
      _permissions['deletePlayer'] = false;
      _permissions['createTeam'] = false;
      _permissions['manageStaff'] = false;
      _permissions['createBattle'] = false;
      _permissions['manageBattle'] = false;
      _permissions['createStrategy'] = false;
      _permissions['manageStrategy'] = false;
    }
  }

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

  Future<void> _createStaff() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'PLEASE FILL ALL CREDENTIALS');
      return;
    }

    // Check if email already exists
    try {
      final existingStaff = await _staffService.getStaffCredentials();
      final emailExists = existingStaff.any((staff) => staff['email'] == email);
      if (emailExists) {
        setState(() => _errorMessage = 'EMAIL ALREADY REGISTERED');
        return;
      }
    } catch (e) {
      // Continue if check fails
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final roleKey = _selectedRole.toLowerCase().replaceAll(' ', '_');
      final perms = Map<String, bool>.from(_permissions);
      perms['readPlayer'] = perms['readPlayer'] ?? true;
      await widget.onStaffCreated?.call({
        'name': name,
        'email': email,
        'password': password,
        'role': roleKey,
        if (roleKey == 'custom' && _customRoleController.text.trim().isNotEmpty)
          'customRoleName': _customRoleController.text.trim(),
        'permissions': perms,
      });

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: surfaceDim,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAppBar(),
              Flexible(child: _isSuccess ? _buildSuccessPhase() : _buildInitializePhase()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: surfaceContainer,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings_rounded, color: primaryContainer, size: 24),
          const SizedBox(width: 16),
          const Text('INITIALIZE PERSONNEL', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5, fontFamily: 'Space Grotesk')),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white38, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializePhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(),
          const SizedBox(height: 32),
          _buildSectionHeader('CORE CREDENTIALS'),
          const SizedBox(height: 16),
          _buildProfilePhotoSection(),
          const SizedBox(height: 16),
          _buildTextField('FULL NAME', 'e.g. MARCUS STERLING', _nameController),
          const SizedBox(height: 12),
          _buildTextField('LOGIN EMAIL', 'name@academy.pro', _emailController),
          const SizedBox(height: 12),
          _buildTextField('SECURED PASSWORD', '••••••••', _passwordController, isPassword: true),
          const SizedBox(height: 32),
          _buildSectionHeader('SELECT DESIGNATION'),
          const SizedBox(height: 16),
          ..._roles.map((role) => _buildRoleCard(role)),
          if (_selectedRole == 'Custom') ...[
            const SizedBox(height: 16),
            _buildTextField('CUSTOM ROLE NAME', 'e.g. Skills coach', _customRoleController),
          ],
          const SizedBox(height: 32),
          _buildTacticalPermissions(),
          const SizedBox(height: 32),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSuccessPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: primaryContainer.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: primaryContainer, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('ONBOARDING SUCCESS', style: TextStyle(color: primaryContainer, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Personnel Record Created', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          const SizedBox(height: 32),
          _buildCredentialCard(),
          const SizedBox(height: 32),
          const Text('Share these credentials with the staff member. They can sign in immediately to the performance portal.', textAlign: TextAlign.center, style: TextStyle(color: outline, fontSize: 12)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryContainer,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('RETURN TO PORTAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryContainer.withOpacity(0.2)),
        gradient: LinearGradient(colors: [surfaceContainer, surfaceHigh.withOpacity(0.5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        children: [
          _buildHandoverRow('GENERATED EMAIL', _emailController.text),
          const Divider(color: Colors.white10, height: 32),
          _buildHandoverRow('ACCESS KEY', _passwordController.text),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: 'Email: ${_emailController.text}\nPassword: ${_passwordController.text}'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CREDENTIALS COPIED')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: surfaceHighest, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.content_copy_rounded, color: primaryGold, size: 16),
                  SizedBox(width: 8),
                  Text('SMART COPY CREDENTIALS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: outline, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PROGRESS PHASE', style: TextStyle(color: outline, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text('1 / 2', style: TextStyle(color: primaryContainer, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(color: surfaceHighest, borderRadius: BorderRadius.circular(2)),
          child: Row(
            children: [
              Expanded(child: Container(decoration: BoxDecoration(color: primaryContainer, borderRadius: BorderRadius.circular(2)))),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.05))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title, style: const TextStyle(color: primaryGold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
        Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.05))),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: outline, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white10),
            filled: true,
            fillColor: surfaceContainer,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: isPassword ? IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(String role) {
    final bool isSelected = _selectedRole == role;
    final Color roleColor = role == 'Coach' ? const Color(0xFF14D7FF) : (role == 'Assistant Coach' ? const Color(0xFFA855F7) : primaryGold);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = role;
          _applyRoleDefaults(role);
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? roleColor.withOpacity(0.05) : surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? roleColor.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(role == 'Coach' ? Icons.psychology : (role == 'Assistant Coach' ? Icons.groups : Icons.settings_input_component), color: roleColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      role == 'Coach'
                          ? 'Head coaching role'
                          : (role == 'Assistant Coach' ? 'Assistant coaching role' : 'Custom role name & permissions'),
                      style: const TextStyle(color: outline, fontSize: 9),
                    ),
                  ],
                ),
              ),
              if (isSelected) 
                Icon(Icons.check_circle_rounded, color: roleColor, size: 20)
              else 
                Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white10, width: 2))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTacticalPermissions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ACCESS RIGHTS', style: TextStyle(color: primaryGold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: surfaceContainer, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Column(
            children: [
              _buildPermissionToggle('Create Player', 'Add new players to roster', 'createPlayer'),
              const Divider(color: Colors.white10, height: 1),
              _buildPermissionToggle('Modify Profile', 'Edit stats and bio data', 'updatePlayer'),
              const Divider(color: Colors.white10, height: 1),
              _buildPermissionToggle('Delete Profile', 'Permanent removal of entities', 'deletePlayer'),
              const Divider(color: Colors.white10, height: 1),
              _buildPermissionToggle('Manage Teams', 'Shift personnel between units', 'createTeam'),
              const Divider(color: Colors.white10, height: 1),
              _buildPermissionToggle('Manage Staff', 'Control academy personnel', 'manageStaff'),
              const Divider(color: Colors.white10, height: 1),
              _buildPermissionToggle('Create Game', 'Schedule games and scrimmages', 'createBattle'),
              const Divider(color: Colors.white10, height: 1),
              _buildPermissionToggle('Manage Game', 'Edit and oversee scheduled games', 'manageBattle'),
              const Divider(color: Colors.white10, height: 1),
              _buildPermissionToggle('Create Strategy', 'Author strategic plays', 'createStrategy'),
              const Divider(color: Colors.white10, height: 1),
              _buildPermissionToggle('Manage Strategy', 'Implement academy strategy', 'manageStrategy'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionToggle(String title, String sub, String key) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(sub, style: const TextStyle(color: outline, fontSize: 10)),
            ],
          ),
          Switch(
            value: _permissions[key] ?? false,
            onChanged: (v) {
              setState(() => _permissions[key] = v);
            },
            activeColor: primaryContainer,
            activeTrackColor: primaryContainer.withOpacity(0.3),
            inactiveThumbColor: outline,
            inactiveTrackColor: surfaceHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createStaff,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
          : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: surfaceHigh,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: primaryContainer.withOpacity(0.3), width: 2),
              ),
              child: _profileImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.file(
                        File(_profileImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, color: outline, size: 32);
                        },
                      ),
                    )
                  : const Icon(Icons.add_a_photo, color: outline, size: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Profile Photo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to upload photo',
            style: TextStyle(
              color: outline.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
