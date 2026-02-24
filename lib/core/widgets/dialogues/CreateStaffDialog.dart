import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:courtiq/core/constants/colors.dart';
import 'package:courtiq/core/widgets/custom_button.dart';
import 'package:courtiq/core/widgets/auth/custom_textfield_createaccount.dart';
import 'package:courtiq/features/staff/service/staff_service.dart';

class CreateStaffDialog extends StatefulWidget {
  final String initialRole;
  final Function(Map<String, String> staff)? onStaffCreated;

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
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  late String _selectedRole;

  final List<String> _roles = ['Coach', 'Assistant Coach', 'Custom'];
  final Map<String, bool> _permissions = {
    'createPlayer': true,
    'addPlayerToTeam': true,
    'readOnlyPlayer': true,
    'modifyPlayerProfile': true,
    'deletePlayerProfile': false,
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialRole.toLowerCase().contains('assistant')) {
      _selectedRole = 'Assistant Coach';
    } else if (widget.initialRole.toLowerCase().contains('custom')) {
      _selectedRole = 'Custom';
    } else {
      _selectedRole = 'Coach';
    }
    _applyRoleDefaults(_selectedRole);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _customRoleController.dispose();
    super.dispose();
  }

  String _mapRoleToApi(String role) {
    if (role == 'Assistant Coach') return 'assistant_coach';
    if (role == 'Custom') return 'custom';
    return 'coach';
  }

  void _applyRoleDefaults(String role) {
    if (role == 'Coach') {
      _permissions['createPlayer'] = true;
      _permissions['addPlayerToTeam'] = true;
      _permissions['readOnlyPlayer'] = true;
      _permissions['modifyPlayerProfile'] = true;
      _permissions['deletePlayerProfile'] = false;
    } else if (role == 'Assistant Coach') {
      _permissions['createPlayer'] = true;
      _permissions['addPlayerToTeam'] = true;
      _permissions['readOnlyPlayer'] = true;
      _permissions['modifyPlayerProfile'] = false;
      _permissions['deletePlayerProfile'] = false;
    } else {
      _permissions['createPlayer'] = false;
      _permissions['addPlayerToTeam'] = false;
      _permissions['readOnlyPlayer'] = true;
      _permissions['modifyPlayerProfile'] = false;
      _permissions['deletePlayerProfile'] = false;
    }
  }

  Future<void> _createStaff() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final customRoleName = _customRoleController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }
    if (_selectedRole == 'Custom' && customRoleName.isEmpty) {
      setState(() => _errorMessage = 'Please enter a custom role name');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_selectedRole == 'Custom') {
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        await _staffService.createStaff(
          name: name,
          email: email,
          password: password,
          role: _mapRoleToApi(_selectedRole),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);

      widget.onStaffCreated?.call({
        'name': name,
        'username': name,
        'email': email,
        'role': _mapRoleToApi(_selectedRole),
        'roleLabel': _selectedRole,
        'customRoleName': _selectedRole == 'Custom' ? customRoleName : '',
        'password': password,
        'permissions': _permissions.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .join(','),
      });

      final roleDisplay = _selectedRole == 'Custom' ? customRoleName : _selectedRole;
      _showCredentialsDialog(context, name, email, password, roleDisplay);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showCredentialsDialog(BuildContext context, String name, String email,
      String password, String role) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: AppColors.green, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Staff Account Created!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '$name ($role)',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _credentialRow('LOGIN EMAIL', email, Icons.email_outlined),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _credentialRow('PASSWORD', password, Icons.lock_outline),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Share these credentials with $name. They can sign in immediately.',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon:
                          const Icon(Icons.copy, size: 16, color: Colors.white),
                      label: const Text('Copy',
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: 'Email: $email\nPassword: $password'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Credentials copied!'),
                              backgroundColor: AppColors.green),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Done',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _credentialRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace')),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: AppColors.green, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Staff',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text('Create login credentials',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Role Selector
              const Text('Role',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: _roles.map((role) {
                  final isSelected = _selectedRole == role;
                  final color = role == 'Coach'
                      ? const Color(0xFF3B82F6)
                      : role == 'Assistant Coach'
                          ? const Color(0xFF8B5CF6)
                          : AppColors.yellow;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: role == 'Custom' ? 0 : 4,
                          left: role == 'Coach' ? 0 : 4),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedRole = role;
                          _applyRoleDefaults(role);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(role,
                                style: TextStyle(
                                    color: isSelected ? color : Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedRole == 'Custom') ...[
                const SizedBox(height: 16),
                CustomTextFieldCreateAccount(
                  label: 'Custom Role Name',
                  hintText: 'e.g. Skill Trainer',
                  controller: _customRoleController,
                ),
              ],
              const SizedBox(height: 20),

              const Text(
                'Permissions',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    _buildPermissionItem('Create players', 'createPlayer'),
                    _buildPermissionItem('Add players to team', 'addPlayerToTeam'),
                    _buildPermissionItem('Read-only players', 'readOnlyPlayer'),
                    _buildPermissionItem('Modify player profile', 'modifyPlayerProfile'),
                    _buildPermissionItem('Delete player profile', 'deletePlayerProfile'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              CustomTextFieldCreateAccount(
                label: 'Full Name',
                hintText: 'e.g. Coach Carter',
                controller: _nameController,
              ),
              const SizedBox(height: 16),

              CustomTextFieldCreateAccount(
                label: 'Login Email',
                hintText: 'carter@academy.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              CustomTextFieldCreateAccount(
                label: 'Password',
                hintText: 'Min 6 characters',
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      backgroundColor: Colors.transparent,
                      textColor: Colors.white60,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: AppColors.green)))
                        : CustomButton(
                            text: 'Create Account',
                            backgroundColor: AppColors.green,
                            textColor: Colors.white,
                            onPressed: _createStaff,
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

  Widget _buildPermissionItem(String label, String key) {
    return CheckboxListTile(
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.green,
      title: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      value: _permissions[key] ?? false,
      onChanged: (val) {
        setState(() {
          _permissions[key] = val ?? false;
        });
      },
    );
  }
}
