import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import 'package:hoopstar/features/login/viewmodel/login_viewmodel.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/auth/custom_textfield_createaccount.dart';
import '../../../core/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewmodel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ... (Icon, Text widgets)

              // Email
              CustomTextFieldCreateAccount(
                label: 'Email',
                hintText: 'your@email.com',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
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

              if (authViewModel.isLoading)
                const CircularProgressIndicator()
              else
                CustomButton(
                  text: 'Sign In',
                  onPressed: () {
                    authViewModel.login(
                      context,
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );
                  },
                ),

              const SizedBox(height: 15),

              InkWell(
                onTap: (){
                  LoginViewmodel.goToResetPassword(context);
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                          color: AppColors.yellow,
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
