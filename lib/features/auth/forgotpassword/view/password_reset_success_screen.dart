import 'package:flutter/material.dart';
import '../../../../routes/routes_names.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  final String role;
  const PasswordResetSuccessScreen({super.key, required this.role});

  // BallChart Design Colors
  static const Color primaryColor = Color(0xFFFF6B00);
  static const Color bgColor = Color(0xFF0A0C10);
  static const Color cardColor = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient light
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.04),
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.06), blurRadius: 150, spreadRadius: 80),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const Spacer(),
                  
                  // Success Icon / Decoration
                  Center(
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: primaryColor.withOpacity(0.15), width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 30,
                              )
                            ]
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: primaryColor,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  const Text(
                    'Password Reset\nSuccessful!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your password has been updated.\nYou can now log in with your new\ncredentials and get back to the game.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  
                  const Spacer(),

                  // Action Button
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
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          RouteNames.login,
                          (route) => false,
                          arguments: role,
                        );
                      },
                      child: const Text(
                        'BACK TO LOGIN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'BallChart Athletic Platform',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
