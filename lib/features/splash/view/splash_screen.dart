import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/routes_names.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../../../core/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait a bit for the splash to show
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final authVm = Provider.of<AuthViewmodel>(context, listen: false);
    final profileVm = Provider.of<ProfileViewmodel>(context, listen: false);

    bool isLoggedIn = await authVm.checkSession();

    if (isLoggedIn) {
      // Fetch profile to check profileCompleted status
      await profileVm.loadProfile();
      final user = profileVm.user;

      if (user != null) {
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
      backgroundColor: const Color(0xFF020617),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero section style logo placeholder
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_basketball,
                size: 80,
                color: AppColors.yellow,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'BALLCHART',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
            ),
          ],
        ),
      ),
    );
  }
}
