import 'package:flutter/material.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../routes/routes_names.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/user_model.dart';

import 'package:provider/provider.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../../management/viewmodel/academy_provider.dart';

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

  Future<void> login(
    BuildContext context,
    String email,
    String password, {
    String? preferredRole,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authRepository.login(
        email,
        password,
        preferredRole: preferredRole,
      );
      Provider.of<ProfileViewmodel>(context, listen: false).setUser(user);
      _setLoading(false);

      if (user.role == 'admin') {
        final academyProvider = Provider.of<AcademyProvider>(context, listen: false);
        academyProvider.loginByRole('academy_owner');
        if (user.teamName != null && user.teamName!.isNotEmpty) {
          academyProvider.updateAcademyProfile(
            academyName: user.teamName!,
            logoUrl: academyProvider.academy.logoUrl,
            ownerName: user.username,
            ownerEmail: user.email,
          );
        }
        Navigator.pushNamedAndRemoveUntil(context, RouteNames.academyDashboard, (route) => false);
      } else if (user.profileCompleted) {
        Navigator.pushNamedAndRemoveUntil(context, RouteNames.mainApp, (route) => false, arguments: user.role);
      } else {
        if (user.role == 'coach' || user.role == 'head_coach' || user.role == 'assistant_coach') {
          Navigator.pushNamedAndRemoveUntil(context, RouteNames.profilecomplete_coach, (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, RouteNames.profilecomplete_player, (route) => false);
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

  Future<void> signup(BuildContext context, String username, String email, String password, String role, {String? academyName}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authRepository.signup(username, email, password, role, academyName: academyName);
      _setLoading(false);

      final bool isAcademySignup = role == 'admin';
      showDialog(
        context: context,
        builder: (context) => CustomDialog(
          title: isAcademySignup ? 'Request Submitted' : 'Success!',
          message: isAcademySignup
              ? 'Your academy signup request has been submitted. Admin will contact you shortly with details. Approval usually happens within 24 hours.'
              : 'Account created successfully. Please log in.',
          isSuccess: true,
          onOk: () {
             if (isAcademySignup) {
               Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (route) => false, arguments: 'admin');
             } else if (role == 'coach' || role == 'head_coach') {
               Navigator.pushNamedAndRemoveUntil(context, RouteNames.profilecomplete_coach, (route) => false);
             } else {
               Navigator.pushNamedAndRemoveUntil(context, RouteNames.profilecomplete_player, (route) => false);
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
      Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (route) => false);
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
