import 'package:flutter/material.dart';
import 'package:courtiq/routes/routes_names.dart';

class NewPasswordViewmodel {
  // Function to navigate to RoleSelecting screen
  static void goToLogin(BuildContext context,String role) {
    Navigator.pushNamed(context, RouteNames.login,arguments: role);
  }
}
