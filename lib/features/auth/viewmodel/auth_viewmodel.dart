import 'package:flutter/material.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../routes/routes_names.dart';

class AuthViewmodel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> login(BuildContext context, String email, String password, String role) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authRepository.login(email, password, role);
      _setLoading(false);
      
      if (user.role == 'coach') {
        Navigator.pushReplacementNamed(context, RouteNames.coachHome);
      } else {
        Navigator.pushReplacementNamed(context, RouteNames.mainApp);
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      showDialog(
        context: context,
        builder: (context) => CustomDialog(
          title: 'Login Failed',
          message: e.toString().replaceAll('Exception: ', ''),
          isSuccess: false,
        ),
      );
    }
  }

  Future<void> signup(BuildContext context, String username, String email, String password, String role) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authRepository.signup(username, email, password, role);
      _setLoading(false);
      
      // Success Dialog and Navigate to Login
      showDialog(
        context: context,
        builder: (context) => CustomDialog(
          title: 'Success!',
          message: 'Account created successfully. Please log in.',
          isSuccess: true,
          onOk: () {
             Navigator.pushReplacementNamed(context, RouteNames.login);
          },
        ),
      );

    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      showDialog(
        context: context,
        builder: (context) => CustomDialog(
          title: 'Signup Failed',
          message: e.toString().replaceAll('Exception: ', ''),
          isSuccess: false,
        ),
      );
    }
  }

  // Navigation helpers
  static void goToRoleSelecting(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.mainApp);
  }

  static void goToLogin(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.login);
  }
}
