import 'package:flutter/material.dart';
import 'package:hoopstar/core/widgets/custom_textfield_createaccount.dart';
import '../../../core/widgets/custom_button.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title Section
                Container(
                  width: 60,  // circle diameter
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFFF59E0B), // yellow background
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
                  'Join as a Coach',
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // Create Account Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: () {
                    // Handle account creation
                    print('Creating account...');
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
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
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
    );
  }

}