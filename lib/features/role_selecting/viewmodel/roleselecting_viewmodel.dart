import 'package:flutter/material.dart';
import 'package:hoopstar/routes/routes_names.dart';

class RoleselectingViewmodel {
  // Function to navigate to RoleSelecting screen
  static void goToAuth(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.auth);
  }
}
