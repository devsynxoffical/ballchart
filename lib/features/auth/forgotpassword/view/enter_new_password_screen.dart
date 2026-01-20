import 'package:flutter/material.dart';
import 'package:courtiq/features/auth/forgotpassword/viewmodel/new_password_viewmodel.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/resetPassword/password_rules.dart';
import '../../../../core/widgets/resetPassword/reset_header.dart';


class EnterNewPasswordScreen extends StatelessWidget {
  final String role;
  const EnterNewPasswordScreen({super.key,required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ResetHeader(
                        bgColor: role == 'coach' ? AppColors.yellow :AppColors.blue,
                        title: 'Reset Password',
                        subtitle: 'Create new password',
                      ),
                      const SizedBox(height: 30),
                      _passwordField('New Password'),
                      const SizedBox(height: 16),
                      _passwordField('Confirm Password'),
                      const SizedBox(height: 16),
                      const PasswordRules(),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Submit New Password',
                        backgroundColor: role == 'coach' ? AppColors.yellow :AppColors.blue,
                        textColor: role == 'coach' ? AppColors.black :AppColors.white,
                        onPressed: () {
                          NewPasswordViewmodel.goToLogin(context,role);
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomButton(
                        text: 'Back',
                        backgroundColor: Colors.white10,
                        textColor: Colors.white,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

    );
  }

  Widget _passwordField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter password',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(Icons.visibility, color: Colors.white38),
          ),
        ),
      ],
    );
  }
}
