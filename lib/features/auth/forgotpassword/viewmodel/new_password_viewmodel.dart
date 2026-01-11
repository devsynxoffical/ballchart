import 'package:flutter/material.dart';
import 'package:hoopstar/routes/routes_names.dart';

class NewPasswordViewmodel {
  // Function to navigate to RoleSelecting screen
  static void goToLogin(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.login);
  }
}
