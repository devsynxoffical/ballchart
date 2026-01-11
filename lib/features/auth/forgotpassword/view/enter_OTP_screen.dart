import 'package:flutter/material.dart';
import 'package:hoopstar/core/widgets/resetPassword/reset_header.dart';
import 'package:hoopstar/features/auth/forgotpassword/viewmodel/otp_viewmodel.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/resetPassword/otp_input.dart';

class EnterOtpScreen extends StatelessWidget {
  const EnterOtpScreen({super.key});

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
                subtitle: 'Enter verification code',
              ),
              const SizedBox(height: 30),
              const Text(
                'Enter 6-digit code sent to your email',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 24),
              const OtpInput(),
              const SizedBox(height: 30),
              CustomButton(
                text: 'Verify Code',
                onPressed: () {
                  OTPViewmodel.goToEnterNewPass(context);
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
    );
  }
}
