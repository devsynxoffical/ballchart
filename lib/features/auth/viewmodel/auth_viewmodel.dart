import 'package:flutter/material.dart';
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

  Future<void> login(BuildContext context, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authRepository.login(email, password);
      _setLoading(false);
      // Navigate to Home/MainApp on success
      Navigator.pushReplacementNamed(context, RouteNames.mainApp);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.toString()}')),
      );
    }
  }

  Future<void> signup(BuildContext context, String username, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authRepository.signup(username, email, password, 'player');
      _setLoading(false);
      // Navigate to Home/MainApp on success
      Navigator.pushReplacementNamed(context, RouteNames.mainApp);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Failed: ${e.toString()}')),
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
