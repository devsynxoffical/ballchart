// app/app_routes.dart
import 'package:flutter/material.dart';
import 'package:courtiq/features/AppNavigator/app_navigator.dart';
import 'package:courtiq/features/auth/completeyourprofile/coach/view/profile_coach_screen.dart';
import 'package:courtiq/features/auth/forgotpassword/view/enter_OTP_screen.dart';
import 'package:courtiq/features/auth/forgotpassword/view/enter_email_screen.dart';
import 'package:courtiq/features/auth/forgotpassword/view/enter_new_password_screen.dart';
import 'package:courtiq/features/auth/view/auth_screen.dart';
import 'package:courtiq/features/battle/view/battle_screen.dart';
import 'package:courtiq/features/home/view/home_screen.dart';
import 'package:courtiq/features/login/view/login_screen.dart';
import 'package:courtiq/features/onboarding/view/onboarding_screen.dart';
import 'package:courtiq/features/profile/view/profile_screen.dart';
import 'package:courtiq/features/role_selecting/view/role_selecting_screen.dart';
import 'package:courtiq/features/strategy/view/strategy_screen.dart';
import 'package:courtiq/features/management/view/academy_dashboard_screen.dart';
import 'package:courtiq/features/staff/view/staff_dashboard_screen.dart';
import 'package:courtiq/features/player/view/player_dashboard_screen.dart';
import 'package:courtiq/routes/routes_names.dart';
import 'package:courtiq/features/coach/home/view/coach_home_screen.dart';
import 'package:courtiq/features/splash/view/splash_screen.dart';

import '../features/auth/completeyourprofile/player/view/profile_player_screen.dart';

class AppRoutes {
  static Route<dynamic> generate(RouteSettings settings) {
    final role = settings.arguments is String ? settings.arguments as String : 'coach';
    switch (settings.name) {
      case RouteNames.onboarding:
        return MaterialPageRoute(builder: (_) => OnboardingScreen());
      case RouteNames.roleselecting: // Deprecated but kept for safety
        return MaterialPageRoute(builder: (_) => RoleSelectingScreen());
      case RouteNames.auth:
        return MaterialPageRoute(builder: (_) => AuthScreen(initialRole: role)); // Generic
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case RouteNames.battle:
        return MaterialPageRoute(builder: (_) => BattleScreen());
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => LoginScreen(role: role)); // Generic
      case RouteNames.strategy:
        return MaterialPageRoute(builder: (_) => StrategyScreen());
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case RouteNames.mainApp:
        if (role == 'admin') {
          return MaterialPageRoute(builder: (_) => const AcademyDashboardScreen());
        }
        return MaterialPageRoute(builder: (_) => AppNavigator(role: role));
      case RouteNames.forgotpassword_enter_email:
        return MaterialPageRoute(builder: (_) => EnterEmailScreen(role: role,));
      case RouteNames.forgotpass_enter_otp:
        return MaterialPageRoute(builder: (_) => EnterOtpScreen(role: role,));
      case RouteNames.forgotpass_enter_new_pass:
        return MaterialPageRoute(builder: (_) => EnterNewPasswordScreen(role: role,));
      case RouteNames.coachHome:
        return MaterialPageRoute(builder: (_) => CoachHomeScreen());
      case RouteNames.profilecomplete_coach:
        return MaterialPageRoute(builder: (_) => CompleteProfileScreenCoach());
      case RouteNames.profilecomplete_player:
        return MaterialPageRoute(builder: (_) => CompleteProfilePlayerScreen());
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case RouteNames.academyDashboard:
        return MaterialPageRoute(builder: (_) => const AcademyDashboardScreen());
      case RouteNames.staffDashboard:
        return MaterialPageRoute(builder: (_) => const StaffDashboardScreen());
      case RouteNames.playerDashboard:
        return MaterialPageRoute(builder: (_) => const PlayerDashboardScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
