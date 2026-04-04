import 'package:flutter/material.dart';
import 'package:courtiq/routes/routes_names.dart';

class OnboardingViewModel {
  // Function to navigate to RoleSelecting screen
  static void goToRoleSelecting(BuildContext context) {
    // Navigate to Sign In instead of Role Selecting
    Navigator.pushReplacementNamed(context, RouteNames.login);
  }
}
