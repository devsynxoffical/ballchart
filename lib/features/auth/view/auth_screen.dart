import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/legal/app_legal_urls.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/routes/routes_names.dart';
import 'package:flutter/services.dart';

class AuthScreen extends StatefulWidget {
  final String initialRole;
  const AuthScreen({super.key, this.initialRole = 'coach'});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _academyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  static const String _selectedRole = 'admin';

  // BallChart Design Colors
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF181710);
  static const Color fieldBgColor = Color(0x801E293B); 
  static const Color fieldBorderColor = Color(0xFF334155); 
  static const Color textColor = Color(0xFFF1F5F9); 

  @override
  void dispose() {
    _fullNameController.dispose();
    _academyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Exit App', style: TextStyle(color: Colors.white)),
        content: const Text('Do you want to exit the application?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Background ambient light
            Positioned(
              top: -100,
              right: -100,
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

            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Register Your Academy',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // Spacer for balance
                        ],
                      ),
                    ),

                    // Header Image
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          bottom: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/header.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              bgColor.withOpacity(0.1),
                              primaryColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content form
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text(
                            'START YOUR ACADEMY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Empower your basketball academy with data-driven management. Create your admin account to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          _buildTextField(
                            controller: _fullNameController,
                            label: 'Full Name (Admin)',
                            hintText: 'Enter administrator name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _academyNameController,
                            label: 'Academy Name',
                            hintText: 'Enter academy name',
                            icon: Icons.sports_basketball_outlined,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hintText: 'academy@example.com',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: '••••••••',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isVisible: _isPasswordVisible,
                            onVisibilityToggle: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            hintText: '••••••••',
                            icon: Icons.security_outlined,
                            isPassword: true,
                            isVisible: _isConfirmPasswordVisible,
                            onVisibilityToggle: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: 32),

                          // CTA Button
                          Consumer<AuthViewmodel>(
                            builder: (context, authViewModel, child) {
                              return SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: authViewModel.isLoading
                                      ? null
                                      : () {
                                          final fullName = _fullNameController.text.trim();
                                          final academyName = _academyNameController.text.trim();
                                          final email = _emailController.text.trim();
                                          final pass = _passwordController.text.trim();
                                          final confirm = _confirmPasswordController.text.trim();
                                          
                                          // Validation
                                          if (fullName.isEmpty) {
                                            _showError('Please enter administrator name');
                                            return;
                                          }
                                          if (academyName.isEmpty) {
                                            _showError('Please enter academy name');
                                            return;
                                          }
                                          if (email.isEmpty) {
                                            _showError('Please enter email address');
                                            return;
                                          }
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                                            _showError('Please enter a valid email address');
                                            return;
                                          }
                                          if (pass.isEmpty) {
                                            _showError('Please enter password');
                                            return;
                                          }
                                          if (pass.length < 6) {
                                            _showError('Password must be at least 6 characters');
                                            return;
                                          }
                                          if (confirm.isEmpty) {
                                            _showError('Please confirm password');
                                            return;
                                          }
                                          if (pass != confirm) {
                                            _showError('Password and confirm password must match');
                                            return;
                                          }
                                          
                                          authViewModel.signup(
                                            context,
                                            fullName,
                                            email,
                                            pass,
                                            _selectedRole,
                                            academyName: academyName,
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: bgColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    shadowColor: primaryColor.withOpacity(0.5),
                                  ),
                                  child: authViewModel.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(color: bgColor, strokeWidth: 3),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'REGISTER ACADEMY',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.chevron_right),
                                          ],
                                        ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),

                          // Footer Text
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                RouteNames.login,
                                arguments: _selectedRole,
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Already part of a team? ',
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Log In',
                                    style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppLegalUrls.inlineTextButtons(context),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: fieldBorderColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !isVisible,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(icon, color: Colors.grey),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}