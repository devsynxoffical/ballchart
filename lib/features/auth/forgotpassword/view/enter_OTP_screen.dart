import 'package:flutter/material.dart';
import 'package:ballchart/features/auth/forgotpassword/viewmodel/otp_viewmodel.dart';

class EnterOtpScreen extends StatelessWidget {
  final String role;
  const EnterOtpScreen({super.key, required this.role});

  // BallChart Design Colors
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF181710);
  static const Color fieldBgColor = Color(0x801E293B); 
  static const Color fieldBorderColor = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background ambient light
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.03),
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.04), blurRadius: 150, spreadRadius: 80),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 32),
                  
                  // Logo Container
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: bgColor,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Verify Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'ve sent a 6-digit verification code to your email address. Please enter it below to proceed.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // OTP Input Placeholder (Since OtpInput is a separate widget, we preserve the layout logic)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) => _buildOtpSquare()),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: bgColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        shadowColor: primaryColor.withOpacity(0.5),
                      ),
                      onPressed: () {
                        OTPViewmodel.goToEnterNewPass(context, role);
                      },
                      child: const Text(
                        'VERIFY CODE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resend Link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Resend logic
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'Didn\'t receive the code? ',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Resend',
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  // Branding Icons
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_basketball_rounded, color: Colors.white12, size: 28),
                        SizedBox(width: 32),
                        Icon(Icons.insights_rounded, color: Colors.white12, size: 28),
                        SizedBox(width: 32),
                        Icon(Icons.emoji_events_rounded, color: Colors.white12, size: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSquare() {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: fieldBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fieldBorderColor),
      ),
      alignment: Alignment.center,
      child: const TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(border: InputBorder.none),
      ),
    );
  }
}
