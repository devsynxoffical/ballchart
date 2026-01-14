// app/app_routes.dart
import 'package:flutter/material.dart';
import 'package:hoopstar/features/AppNavigator/app_navigator.dart';
import 'package:hoopstar/features/auth/completeyourprofile/coach/view/profile_coach_screen.dart';
import 'package:hoopstar/features/auth/forgotpassword/view/enter_OTP_screen.dart';
import 'package:hoopstar/features/auth/forgotpassword/view/enter_email_screen.dart';
import 'package:hoopstar/features/auth/forgotpassword/view/enter_new_password_screen.dart';
import 'package:hoopstar/features/auth/view/auth_screen.dart';
import 'package:hoopstar/features/battle/view/battle_screen.dart';
import 'package:hoopstar/features/home/view/home_screen.dart';
import 'package:hoopstar/features/login/view/login_screen.dart';
import 'package:hoopstar/features/onboarding/view/onboarding_screen.dart';
import 'package:hoopstar/features/profile/view/profile_screen.dart';
import 'package:hoopstar/features/role_selecting/view/role_selecting_screen.dart';
import 'package:hoopstar/features/strategy/view/strategy_screen.dart';
import 'package:hoopstar/routes/routes_names.dart';
import 'package:hoopstar/features/coach/home/view/coach_home_screen.dart';

class AppRoutes {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.onboarding:
        return MaterialPageRoute(builder: (_) => OnboardingScreen());
      case RouteNames.roleselecting:
        return MaterialPageRoute(builder: (_) => RoleSelectingScreen());
      case RouteNames.auth:
        final role = settings.arguments as String? ?? 'player';
        return MaterialPageRoute(builder: (_) => AuthScreen(role: role));
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case RouteNames.battle:
        return MaterialPageRoute(builder: (_) => BattleScreen());
      case RouteNames.login:
        final role = settings.arguments as String? ?? 'player';
        return MaterialPageRoute(builder: (_) => LoginScreen(role: role));
      case RouteNames.strategy:
        return MaterialPageRoute(builder: (_) => StrategyScreen());
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case RouteNames.mainApp:
        return MaterialPageRoute(builder: (_) => AppNavigator());
      case RouteNames.forgotpassword_enter_email:
        return MaterialPageRoute(builder: (_) => EnterEmailScreen());
      case RouteNames.forgotpass_enter_otp:
        return MaterialPageRoute(builder: (_) => EnterOtpScreen());
      case RouteNames.forgotpass_enter_new_pass:
        return MaterialPageRoute(builder: (_) => EnterNewPasswordScreen());
      case RouteNames.coachHome:
        return MaterialPageRoute(builder: (_) => CoachHomeScreen());
      case RouteNames.profilecomplete_coach:
        return MaterialPageRoute(builder: (_) => CompleteProfileScreenCoach());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
