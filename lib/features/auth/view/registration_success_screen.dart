import 'package:flutter/material.dart';
import '../../../routes/routes_names.dart';
import 'academy_setup_guide_sheet.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final String role;
  const RegistrationSuccessScreen({super.key, required this.role});

  // BallChart Design Colors
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF181710);
  static const Color cardColor = Color(0xFF1E293B); // slate-800

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
        title: const Text(
          'Registration Success',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient light
          Positioned(
            top: 50,
            left: -50,
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
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                  const SizedBox(height: 24),
                  // Hero Image/Gradient Area
                  Container(
                    width: double.infinity,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          cardColor.withOpacity(0.5),
                          primaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Center(
                            child: Icon(
                              Icons.sports_basketball_rounded,
                              color: primaryColor.withOpacity(0.2),
                              size: 120,
                            ),
                          ),
                        ),
                        // Top Right Badge
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: primaryColor.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: primaryColor, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 16,
                          bottom: 16,
                          child: _PillLabel(text: 'ACADEMY LIVE'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Icon
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.15),
                          blurRadius: 30,
                        )
                      ]
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: primaryColor, size: 38),
                  ),
                  const SizedBox(height: 24),

                  // Texts
                  const Text(
                    'Welcome to the\nAcademy!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, height: 1.5),
                      children: const [
                        TextSpan(text: 'Your basketball academy is now\nofficially registered on '),
                        TextSpan(
                          text: 'BallChart',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '.\nGet ready to scout, track, and lead\nyour team to victory.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Stat Cards
                  const Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.groups_rounded, title: 'ROSTER', value: 'Empty')),
                      SizedBox(width: 16),
                      Expanded(child: _StatCard(icon: Icons.insert_chart_outlined_rounded, title: 'ANALYTICS', value: 'Ready')),
                    ],
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
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          RouteNames.login,
                          (route) => false,
                          arguments: role,
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('GO TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => showAcademySetupGuide(context),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                        children: const [
                          TextSpan(text: 'Need help setting up? '),
                          TextSpan(
                            text: 'View Guide',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  final String text;
  const _PillLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RegistrationSuccessScreen.primaryColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: RegistrationSuccessScreen.primaryColor.withOpacity(0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: RegistrationSuccessScreen.bgColor,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _StatCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: RegistrationSuccessScreen.cardColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)), // slate-700
      ),
      child: Column(
        children: [
          Icon(icon, color: RegistrationSuccessScreen.primaryColor, size: 28),
          const SizedBox(height: 12),
          Text(
            title, 
            style: TextStyle(
              color: Colors.white.withOpacity(0.5), 
              fontSize: 12, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 20, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}
