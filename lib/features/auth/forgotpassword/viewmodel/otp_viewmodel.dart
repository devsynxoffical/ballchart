import 'package:flutter/material.dart';
import 'package:hoopstar/routes/routes_names.dart';

class OTPViewmodel {
  // Function to navigate to RoleSelecting screen
  static void goToEnterNewPass(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.forgotpass_enter_new_pass);
  }
}
