import 'package:flutter/material.dart';
import 'package:hoopstar/core/widgets/auth/custom_textfield_createaccount.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:hoopstar/core/widgets/auth/password_rules_widget.dart';



class AuthScreen extends StatefulWidget {
  final String role;
  const AuthScreen({super.key, required this.role});


  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();
  bool _showPasswordRules = false;

  bool _isPasswordVisible = false;

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
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      color: widget.role == 'coach' ? AppColors.yellow :AppColors.blue, // yellow background
                      shape: BoxShape.circle,    // makes it a circle
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,       // icon color
                      size: 30,                  // icon size
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join as a ${widget.role == 'coach' ? 'Coach' : 'Player'}',
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
                              backgroundColor: widget.role == 'coach' ? AppColors.yellow :AppColors.blue,
                              onPressed: () {
                                authViewModel.signup(
                                  context,
                                  _fullNameController.text.trim(),
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                  widget.role,
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
                        // Navigate to sign in screen
                        print('Navigate to Sign In');

                      },
                      child: Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: const TextStyle(
                                color: AppColors.yellow,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Navigate to Sign In
                                  Navigator.pushNamed(context, '/login', arguments: widget.role);
                                  print('Sign In tapped');
                                },
                            ),
                          ],
                        ),
                      )
                    ),
                  ),
              
                  const SizedBox(height: 40),
              ]
              ),
            ),
          ),
        ),
    );
  }

}