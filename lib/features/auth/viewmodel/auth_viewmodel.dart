import 'package:flutter/material.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../routes/routes_names.dart';
import '../../../core/services/api_service.dart';

import 'package:provider/provider.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';

class AuthViewmodel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final ApiService _apiService = ApiService();

  Future<bool> checkSession() async {
    final token = await _apiService.getToken();
    return token != null;
  }

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
      
      if (user.profileCompleted) {
        Navigator.pushReplacementNamed(context, RouteNames.mainApp, arguments: user.role);
      } else {
        if (user.role == 'coach') {
          Navigator.pushReplacementNamed(context, RouteNames.profilecomplete_coach);
        } else {
          Navigator.pushReplacementNamed(context, RouteNames.profilecomplete_player);
        }
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
             if (role == 'coach') {
               Navigator.pushReplacementNamed(context, RouteNames.profilecomplete_coach);
             } else {
               Navigator.pushReplacementNamed(context, RouteNames.profilecomplete_player);
             }
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

  Future<void> logout(BuildContext context) async {
    await _authRepository.logout();
    if (context.mounted) {
      Provider.of<ProfileViewmodel>(context, listen: false).clearProfile();
      Navigator.pushNamedAndRemoveUntil(context, RouteNames.onboarding, (route) => false);
    }
  }

  // Navigation helpers
  static void goToRoleSelecting(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.roleselecting);
  }

  static void goToLogin(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.login);
  }
}
