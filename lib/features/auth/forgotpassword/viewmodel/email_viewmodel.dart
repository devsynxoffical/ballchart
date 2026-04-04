import 'package:flutter/material.dart';
import 'package:courtiq/routes/routes_names.dart';

class EmailViewmodel {
  // Function to navigate to RoleSelecting screen
  static void goToEnterOTP(BuildContext context,String role) {
    Navigator.pushNamed(context, RouteNames.forgotpass_enter_otp,arguments: role);
  }
}
