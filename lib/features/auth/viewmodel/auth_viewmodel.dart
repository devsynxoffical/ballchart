import 'package:flutter/material.dart';
import '../../../core/utils/user_friendly_errors.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../routes/routes_names.dart';
import '../../../core/services/api_service.dart';

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
      Provider.of<AcademyProvider>(context, listen: false).setCurrentUser(user);
      _setLoading(false);

      if (user.role == 'admin') {
        final academyProvider = Provider.of<AcademyProvider>(context, listen: false);
        final academyName = (user.academyName ?? user.teamName ?? '').trim();
        if (academyName.isNotEmpty) {
          academyProvider.updateAcademyProfile(
            academyName: academyName,
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
      final copy = resolveAuthDialogCopy(e, isSignup: false);
      _errorMessage = copy.message;
      notifyListeners();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => CustomDialog(
          title: copy.title,
          message: copy.message,
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
      if (isAcademySignup) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.registration_success,
          (route) => false,
          arguments: 'admin',
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => CustomDialog(
            title: 'Success!',
            message: 'Account created successfully. Please log in.',
            isSuccess: true,
            onOk: () {
              if (role == 'coach' || role == 'head_coach') {
                Navigator.pushNamedAndRemoveUntil(context, RouteNames.profilecomplete_coach, (route) => false);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, RouteNames.profilecomplete_player, (route) => false);
              }
            },
          ),
        );
      }

    } catch (e) {
      _setLoading(false);
      final copy = resolveAuthDialogCopy(e, isSignup: true);
      _errorMessage = copy.message;
      notifyListeners();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => CustomDialog(
          title: copy.title,
          message: copy.message,
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
  static void goToLogin(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.login);
  }
}
