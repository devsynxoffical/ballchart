import 'package:flutter/material.dart';
import 'package:courtiq/core/widgets/auth/custom_textfield_createaccount.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:courtiq/core/widgets/auth/password_rules_widget.dart';
import 'package:courtiq/routes/routes_names.dart';
import 'package:flutter/services.dart';



class AuthScreen extends StatefulWidget {
  final String initialRole;
  const AuthScreen({super.key, this.initialRole = 'coach'});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _academyNameController = TextEditingController(); // NEW
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();
  bool _showPasswordRules = false;
  bool _isPasswordVisible = false;
  static const String _selectedRole = 'admin';

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _showPasswordRules = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _academyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Exit App', style: TextStyle(color: Colors.white)),
        content: const Text('Do you want to exit the application?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.amber)),
          ),
        ],
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
        backgroundColor: const Color(0xFF020617),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title Section
                    Container(
                      width: 60,  // circle diameter
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.yellow, // yellow background
                        shape: BoxShape.circle,    // makes it a circle
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,       // icon color
                        size: 30,                  // icon size
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    const Text(
                          'BallChart',
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    const SizedBox(height: 8),
                    Text(
                      'Register Academy',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                
                    const SizedBox(height: 40),
                
                    // Form Fields
                    CustomTextFieldCreateAccount(
                      label: 'Full Name',
                      hintText: 'Enter your name',
                      controller: _fullNameController,
                    ),
                
                    const SizedBox(height: 20),
                
                    CustomTextFieldCreateAccount(
                      label: 'Academy/Organization Name',
                      hintText: 'Enter academy name',
                      controller: _academyNameController,
                    ),
                    const SizedBox(height: 20),

                    CustomTextFieldCreateAccount(
                      label: 'Phone Number',
                      hintText: '+1555000-0000',
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                    ),
                
                    const SizedBox(height: 20),
                
                    CustomTextFieldCreateAccount(
                      label: 'Email',
                      hintText: 'your@email.com',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                
                    const SizedBox(height: 20),
  
                    CustomTextFieldCreateAccount(
                      label: 'Password',
                      hintText: 'Create a strong password',
                      obscureText: !_isPasswordVisible,
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
  
                    if (_showPasswordRules) ...[
                      const SizedBox(height: 12),
                      const PasswordRulesWidget(),
                    ],
  
  
  
                    const SizedBox(height: 40),
                
                    // Create Account Button
                    Consumer<AuthViewmodel>(
                      builder: (context, authViewModel, child) {
                        return authViewModel.isLoading
                            ? const CircularProgressIndicator()
                            : CustomButton(
                                text: 'Create Account',
                                backgroundColor: AppColors.yellow,
                                onPressed: () {
                                  authViewModel.signup(
                                    context,
                                    _fullNameController.text.trim(),
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                    _selectedRole,
                                    academyName: _academyNameController.text.trim(),
                                  );
                                },
                              );
                      },
                    ),
                
                    const SizedBox(height: 30),
                
                    // Sign In Option
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            RouteNames.login,
                            arguments: _selectedRole,
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: AppColors.yellow,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              
                  const SizedBox(height: 40),
              ]
              ),
            ),
          ),
        ),
      ),
    );
  }

}