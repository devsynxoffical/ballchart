import 'package:flutter/material.dart';
import 'package:ballchart/core/utils/app_messenger.dart';
import 'package:ballchart/features/auth/forgotpassword/viewmodel/email_viewmodel.dart';

class EnterEmailScreen extends StatefulWidget {
  final String role;
  const EnterEmailScreen({super.key, required this.role});

  @override
  State<EnterEmailScreen> createState() => _EnterEmailScreenState();
}

class _EnterEmailScreenState extends State<EnterEmailScreen> {
  final TextEditingController _emailController = TextEditingController();

  // BallChart Design Colors
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF181710);
  static const Color fieldBgColor = Color(0x801E293B);
  static const Color fieldBorderColor = Color(0xFF334155);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background ambient light
          Positioned(
            top: -100,
            right: -100,
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
                              Icons.lock_reset_rounded,
                              color: bgColor,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 32),

                          const Text(
                            'Forgot Password',
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
                            'No worries, it happens. Enter the email address associated with your BallChart account and we\'ll send you a link to reset your password.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Email Field
                          const Text(
                            'EMAIL ADDRESS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: fieldBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: fieldBorderColor),
                            ),
                            child: TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                hintText: 'coach@ballchart.com',
                                hintStyle: TextStyle(color: Colors.grey),
                                prefixIcon: Icon(Icons.mail_outline, color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

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
                                if (_emailController.text.trim().isEmpty) {
                                  AppMessenger.showSnackBar(
                                    context,
                                    const SnackBar(content: Text('Please enter email address')),
                                  );
                                  return;
                                }
                                EmailViewmodel.goToEnterOTP(context, widget.role);
                              },
                              child: const Text(
                                'SEND RESET LINK',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Footer Link
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Remembered your password? ',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Log in here',
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
                                Icon(Icons.insert_chart_outlined_rounded, color: Colors.white12, size: 28),
                                SizedBox(width: 32),
                                Icon(Icons.query_stats_rounded, color: Colors.white12, size: 28),
                                SizedBox(width: 32),
                                Icon(Icons.bar_chart_rounded, color: Colors.white12, size: 28),
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
}
