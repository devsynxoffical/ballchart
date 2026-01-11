import 'package:flutter/material.dart';
import 'package:hoopstar/core/widgets/resetPassword/reset_header.dart';
import 'package:hoopstar/features/auth/forgotpassword/viewmodel/email_viewmodel.dart';
import '../../../../core/widgets/custom_button.dart';


class EnterEmailScreen extends StatelessWidget {
  const EnterEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ResetHeader(
                title: 'Reset Password',
                subtitle: 'Enter your registered email',
              ),
              const SizedBox(height: 40),
              _inputField('Email Address', 'your@email.com'),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Send Verification Code',
                onPressed: () {
                  EmailViewmodel.goToEnterOTP(context);
                },
              ),
              const SizedBox(height: 14),
              CustomButton(
                text: 'Back to Login',
                backgroundColor: Colors.white10,
                textColor: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
