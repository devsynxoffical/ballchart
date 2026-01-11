import 'package:flutter/material.dart';
import 'package:hoopstar/routes/routes_names.dart';

class LoginViewmodel {
  // Function to navigate to RoleSelecting screen
  static void goToResetPassword(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.forgotpassword_enter_email);
  }

  static void goToMainPage(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.mainApp);
  }
}
