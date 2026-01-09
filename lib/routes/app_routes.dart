// app/app_routes.dart
import 'package:flutter/material.dart';
import 'package:hoopstar/features/auth/view/auth_screen.dart';
import 'package:hoopstar/features/battle/view/battle_screen.dart';
import 'package:hoopstar/features/home/view/home_screen.dart';
import 'package:hoopstar/features/login/view/login_screen.dart';
import 'package:hoopstar/features/onboarding/view/onboarding_screen.dart';
import 'package:hoopstar/features/role_selecting/view/role_selecting_screen.dart';
import 'package:hoopstar/routes/routes_names.dart';

class AppRoutes {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.onboarding:
        return MaterialPageRoute(builder: (_) => OnboardingScreen());
      case RouteNames.roleselecting:
        return MaterialPageRoute(builder: (_) => RoleSelectingScreen());
      case RouteNames.auth:
        return MaterialPageRoute(builder: (_) => AuthScreen());
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case RouteNames.battle:
        return MaterialPageRoute(builder: (_) => BattleScreen());
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
