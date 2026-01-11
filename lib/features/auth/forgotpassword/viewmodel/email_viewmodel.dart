import 'package:flutter/material.dart';
import 'package:hoopstar/routes/routes_names.dart';

class EmailViewmodel {
  // Function to navigate to RoleSelecting screen
  static void goToEnterOTP(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.forgotpass_enter_otp);
  }
}
