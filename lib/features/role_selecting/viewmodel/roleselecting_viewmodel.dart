import 'package:flutter/material.dart';
import 'package:courtiq/routes/routes_names.dart';

class RoleselectingViewmodel {
  // Function to navigate to RoleSelecting screen
  static void goToAuth(BuildContext context, String role) {
    Navigator.pushReplacementNamed(context, RouteNames.auth, arguments: role);
  }
}
