import 'package:flutter/material.dart';
import 'package:ballchart/core/utils/app_messenger.dart';
import '../../../../routes/routes_names.dart';

class EnterNewPasswordScreen extends StatefulWidget {
  final String role;
  const EnterNewPasswordScreen({super.key, required this.role});

  @override
  State<EnterNewPasswordScreen> createState() => _EnterNewPasswordScreenState();
}

class _EnterNewPasswordScreenState extends State<EnterNewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  // BallChart Design Colors
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF181710);
  static const Color fieldBgColor = Color(0x801E293B); 
  static const Color fieldBorderColor = Color(0xFF334155);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background ambient light
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.03),
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.04), blurRadius: 150, spreadRadius: 80),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 32),
                  
                  // Logo Container
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.shield_rounded,
                      color: bgColor,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Set New Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose a strong password to secure your account and get back to the academy.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Password Field
                  _buildLabel('NEW PASSWORD'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Enter new password',
                    icon: Icons.lock_outline,
                    isVisible: _isPasswordVisible,
                    onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  const SizedBox(height: 24),

                  // Confirm Password Field
                  _buildLabel('CONFIRM PASSWORD'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _confirmController,
                    hintText: 'Confirm new password',
                    icon: Icons.verified_user_outlined,
                    isVisible: _isConfirmVisible,
                    onToggle: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                  ),
                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: fieldBgColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: fieldBorderColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Use at least 8 characters with a mix of letters and numbers.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: bgColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        shadowColor: primaryColor.withOpacity(0.5),
                      ),
                      onPressed: () {
                        if (_passwordController.text.trim().isEmpty ||
                            _confirmController.text.trim().isEmpty) {
                          AppMessenger.showSnackBar(context, 
                            const SnackBar(content: Text('Please fill password fields')),
                          );
                          return;
                        }
                        if (_passwordController.text.trim() != _confirmController.text.trim()) {
                          AppMessenger.showSnackBar(context, 
                            const SnackBar(content: Text('Passwords do not match')),
                          );
                          return;
                        }
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          RouteNames.password_reset_success,
                          (route) => false,
                          arguments: widget.role,
                        );
                      },
                      child: const Text(
                        'SUBMIT NEW PASSWORD',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fieldBorderColor),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}
