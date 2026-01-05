import 'package:flutter/material.dart';
import 'package:hoopstar/routes/routes_names.dart';

class OnboardingViewModel {
  // Function to navigate to RoleSelecting screen
  static void goToRoleSelecting(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.roleselecting);
  }
}
