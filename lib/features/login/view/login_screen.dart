import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import 'package:hoopstar/features/login/viewmodel/login_viewmodel.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/auth/custom_textfield_createaccount.dart';
import '../../../core/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

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
              // Title Section
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.role == 'coach' ? AppColors.yellow :AppColors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.role == 'coach' ? 'Coach' : 'Player'} Sign In',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

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
                  textColor: widget.role == 'coach' ? AppColors.black :AppColors.white,
                  backgroundColor: widget.role == 'coach' ? AppColors.yellow :AppColors.blue,
                  onPressed: () {
                    authViewModel.login(
                      context,
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                      widget.role,
                    );
                  },
                ),

              const SizedBox(height: 15),

              InkWell(
                onTap: (){
                  LoginViewmodel.goToResetPassword(context,widget.role);
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
                   Navigator.pushNamed(context, '/auth', arguments: widget.role);
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
