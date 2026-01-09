import 'package:flutter/material.dart';
import '../../../core/widgets/auth/custom_textfield_createaccount.dart';
import '../../../core/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  // ✅ MISSING VARIABLES (FIX)
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose(); // ✅ always dispose controllers
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

              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Hoop Star',
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

              // Email
              const CustomTextFieldCreateAccount(
                label: 'Email',
                hintText: 'your@email.com',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // Password
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
                    color: Colors.white60,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Button
              CustomButton(
                text: 'Sign In',
                onPressed: () {
                  debugPrint('Creating account...');
                },
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: () {
                  debugPrint('Navigate to Sign In');
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Create an account? ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
