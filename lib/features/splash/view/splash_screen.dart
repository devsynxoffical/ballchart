import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/routes_names.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../../management/viewmodel/academy_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // BallChart Splash Assets & Colors
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF12110A); // Background dark

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait a bit for the splash to show
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    final authVm = Provider.of<AuthViewmodel>(context, listen: false);
    final profileVm = Provider.of<ProfileViewmodel>(context, listen: false);

    bool isLoggedIn = await authVm.checkSession();

    if (isLoggedIn) {
      // Fetch profile to check profileCompleted status
      await profileVm.loadProfile(forceRefresh: true);
      final user = profileVm.user;

      if (user != null) {
        // Keep AcademyProvider in sync so admin dashboard permissions (Tactical Actions) work
        // after cold start — login() already does this; splash session restore did not.
        Provider.of<AcademyProvider>(context, listen: false).setCurrentUser(user);

        if (user.role == 'admin') {
          Navigator.pushReplacementNamed(context, RouteNames.academyDashboard);
        } else if (user.profileCompleted) {
          Navigator.pushReplacementNamed(context, RouteNames.mainApp, arguments: user.role);
        } else {
          if (user.role == 'coach' || user.role == 'assistant_coach' || user.role == 'head_coach') {
            Navigator.pushReplacementNamed(context, RouteNames.profilecomplete_coach);
          } else {
            Navigator.pushReplacementNamed(context, RouteNames.profilecomplete_player);
          }
        }
        return;
      }
    }

    // Default fallback: start directly at login flow
    Navigator.pushReplacementNamed(context, RouteNames.login, arguments: 'admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Dramatic Image with Overlay
          Opacity(
            opacity: 0.3,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0, 0, 0, 1, 0,
              ]), // Grayscale filter
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuA-Hya9BuM2IL-ZyiIS4YT66joAEkQZBmzNyMGvHBGxEfF3ZRF-Kkaf_gNCpOoJdcphi_o1c32ZlqwzrfK-hggZ4PUeViC9tqpfrzDD7xbFLO5SqcilSEtyZ-LOYX8jZJtJJe6Z0mET5G9ip_aQexyDzPWmDXgs4G4AJCVeHuqc4w4FAgxywOJZWhhd-xZO9GJR0N_sDzwC2IaJYg_THnPKRKj_qBebT3NjdLJC1iOklQp9YjRau3i0zE39OUSEknsLaXaYtGoQbyjh',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bgColor,
                  bgColor.withOpacity(0.8),
                  bgColor,
                ],
              ),
            ),
          ),

          // Decorative Elements
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.05),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.05),
                    blurRadius: 120,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar / Status Placeholder
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.sensors, color: primaryColor.withOpacity(0.5), size: 24),
                      Text(
                        'EST. 2024',
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 50,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.query_stats,
                          color: bgColor,
                          size: 70,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Text Branding
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -1,
                          ),
                          children: [
                            TextSpan(text: 'BALL', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'CHART', style: TextStyle(color: primaryColor)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Divider & Subtitle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 32, height: 1, color: primaryColor.withOpacity(0.4)),
                          const SizedBox(width: 8),
                          const Text(
                            'ELITE BASKETBALL ACADEMY',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 32, height: 1, color: primaryColor.withOpacity(0.4)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          'Master the game through data-driven precision and professional-grade training.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Actions / Loading Indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 48.0, left: 32, right: 32),
                  child: Column(
                    children: [
                      // Loading State
                      Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 0.33,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Minimal Footer Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_basketball, color: primaryColor.withOpacity(0.3), size: 24),
                          const SizedBox(width: 32),
                          Icon(Icons.insights_rounded, color: primaryColor.withOpacity(0.3), size: 24),
                          const SizedBox(width: 32),
                          Icon(Icons.emoji_events, color: primaryColor.withOpacity(0.3), size: 24),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      const Text(
                        'UNLOCKING PEAK PERFORMANCE',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
