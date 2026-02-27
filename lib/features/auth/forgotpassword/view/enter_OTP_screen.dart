import 'package:flutter/material.dart';
import 'package:courtiq/core/widgets/resetPassword/reset_header.dart';
import 'package:courtiq/features/auth/forgotpassword/viewmodel/otp_viewmodel.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/resetPassword/otp_input.dart';

class EnterOtpScreen extends StatelessWidget {
  final String role;
  const EnterOtpScreen({super.key,required this.role});

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
              ResetHeader(
                bgColor: AppColors.yellow,
                title: 'BallChart',
                subtitle: 'Password Recovery',
              ),
              const SizedBox(height: 16),
              const Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 30),
              const Text(
                'Enter 6-digit code sent to your email',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 24),
              const OtpInput(),
              const SizedBox(height: 30),
              CustomButton(
                backgroundColor: AppColors.yellow,
                text: 'Verify Code',
                textColor: AppColors.black,
                onPressed: () {
                  OTPViewmodel.goToEnterNewPass(context,role);
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
