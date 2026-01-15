import 'package:flutter/material.dart';
import 'package:hoopstar/routes/routes_names.dart';

class RoleselectingViewmodel {
  // Function to navigate to RoleSelecting screen
  static void goToAuth(BuildContext context, String role) {
    Navigator.pushNamed(context, RouteNames.login, arguments: role);
  }
}
