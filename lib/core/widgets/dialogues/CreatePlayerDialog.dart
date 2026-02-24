import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:courtiq/core/constants/colors.dart';
import 'package:courtiq/core/widgets/custom_button.dart';
import 'package:courtiq/core/widgets/auth/custom_textfield_createaccount.dart';
import 'package:courtiq/features/staff/service/staff_service.dart';

class CreatePlayerDialog extends StatefulWidget {
  final Function(Map<String, String> player)? onPlayerCreated;

  const CreatePlayerDialog({super.key, this.onPlayerCreated});

  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  final StaffService _staffService = StaffService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  String _selectedPosition = 'Point Guard';

  final List<String> _positions = [
    'Point Guard',
    'Shooting Guard',
    'Small Forward',
    'Power Forward',
    'Center',
  ];

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
      setState(() => _errorMessage = 'Name, email and password are required');
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
      await _staffService.createPlayer(
        name: name,
        email: email,
        password: password,
        number: _numberController.text.trim(),
        position: _selectedPosition,
      );

      if (!mounted) return;
      Navigator.pop(context);

      widget.onPlayerCreated?.call({
        'name': name,
        'email': email,
        'tempPassword': password,
        'number': _numberController.text.trim(),
        'position': _selectedPosition,
      });

      _showCredentialsDialog(context, name, email, password);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showCredentialsDialog(
      BuildContext context, String name, String email, String password) {
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
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: AppColors.blue, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Player Account Created!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '$name • $_selectedPosition',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.yellow.withValues(alpha: 0.3)),
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
                      'Share these credentials with $name. They can sign in as a player immediately.',
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
                      color: AppColors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: AppColors.blue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Player',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text('Create player login credentials',
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

              CustomTextFieldCreateAccount(
                label: 'Full Name',
                hintText: 'e.g. Michael Jordan',
                controller: _nameController,
              ),
              const SizedBox(height: 16),

              CustomTextFieldCreateAccount(
                label: 'Login Email',
                hintText: 'player@academy.com',
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
              const SizedBox(height: 16),

              // Jersey Number & Position Row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomTextFieldCreateAccount(
                      label: 'Number',
                      hintText: '#23',
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Position',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPosition,
                              dropdownColor: const Color(0xFF0F172A),
                              style: const TextStyle(color: Colors.white),
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                              isExpanded: true,
                              items: _positions.map((pos) {
                                return DropdownMenuItem(
                                  value: pos,
                                  child: Text(pos,
                                      style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedPosition = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
                                    strokeWidth: 3, color: AppColors.blue)))
                        : CustomButton(
                            text: 'Create Player',
                            backgroundColor: AppColors.blue,
                            textColor: Colors.white,
                            onPressed: _createPlayer,
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
}
