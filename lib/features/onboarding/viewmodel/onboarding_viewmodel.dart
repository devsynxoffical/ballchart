import 'package:flutter/material.dart';
import 'package:courtiq/routes/routes_names.dart';

class OnboardingViewModel {
  // Function to navigate to RoleSelecting screen
  static void goToRoleSelecting(BuildContext context) {
    Navigator.pushReplacementNamed(context, RouteNames.roleselecting);
  }
}
