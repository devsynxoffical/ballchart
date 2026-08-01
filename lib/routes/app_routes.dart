// app/app_routes.dart
import 'package:flutter/material.dart';
import 'package:ballchart/features/AppNavigator/app_navigator.dart';
import 'package:ballchart/features/auth/completeyourprofile/coach/view/profile_coach_screen.dart';
import 'package:ballchart/features/auth/forgotpassword/view/enter_OTP_screen.dart';
import 'package:ballchart/features/auth/forgotpassword/view/enter_email_screen.dart';
import 'package:ballchart/features/auth/forgotpassword/view/enter_new_password_screen.dart';
import 'package:ballchart/features/auth/forgotpassword/view/password_reset_success_screen.dart';
import 'package:ballchart/features/auth/view/auth_screen.dart';
import 'package:ballchart/features/auth/view/registration_success_screen.dart';
import 'package:ballchart/features/login/view/login_screen.dart';
import 'package:ballchart/features/management/view/academy_dashboard_screen.dart';
import 'package:ballchart/features/splash/view/splash_screen.dart';

import '../features/auth/completeyourprofile/player/view/profile_player_screen.dart';

class AppRoutes {
  static Route<dynamic> generate(RouteSettings settings) {
    final role = settings.arguments is String ? settings.arguments as String : 'coach';
    switch (settings.name) {
      case '/':
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/auth':
        return MaterialPageRoute(builder: (_) => AuthScreen(initialRole: role));
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen(role: role));
      case '/mainApp':
        if (role == 'admin') {
          return MaterialPageRoute(builder: (_) => const AcademyDashboardScreen());
        }
        return MaterialPageRoute(builder: (_) => AppNavigator(role: role));
      case '/forgotpassword_enter_email':
        return MaterialPageRoute(builder: (_) => EnterEmailScreen(role: role));
      case '/forgotpass_enter_otp':
        return MaterialPageRoute(builder: (_) => EnterOtpScreen(role: role));
      case '/forgotpass_enter_new_pass':
        return MaterialPageRoute(builder: (_) => EnterNewPasswordScreen(role: role));
      case '/registration_success':
        return MaterialPageRoute(builder: (_) => RegistrationSuccessScreen(role: role));
      case '/password_reset_success':
        return MaterialPageRoute(builder: (_) => PasswordResetSuccessScreen(role: role));
      case '/profilecomplete_coach':
        return MaterialPageRoute(builder: (_) => CompleteProfileScreenCoach());
      case '/profilecomplete_player':
        return MaterialPageRoute(builder: (_) => CompleteProfilePlayerScreen());
      case '/academyDashboard':
        return MaterialPageRoute(builder: (_) => const AcademyDashboardScreen());

      default:
        // Never leave users on a dead "Route not found" screen — send them
        // back to splash so auth can re-route cleanly.
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
