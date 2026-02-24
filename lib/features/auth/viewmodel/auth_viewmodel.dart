import 'package:flutter/material.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../routes/routes_names.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/user_model.dart';

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
    // Demo Login Bypass
    if (email.startsWith('demo_') && password == 'demo123') {
      _setLoading(true);
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      
      String demoRole = 'coach';
      String teamName = 'Elite Dunkers';
      List<String> assignedTeams = ['Elite Dunkers'];
      
      String demoId = 'demo_c_1';

      if (email.contains('head')) {
        demoRole = 'head_coach';
        demoId = 'demo_hc_1';
        teamName = 'Organization HQ';
        assignedTeams = ['Thunder Squad', 'Rising Stars', 'Elite Dunkers'];
      } else if (email.contains('asst')) {
        demoRole = 'assistant_coach';
        demoId = 'demo_ac_1';
        teamName = 'Rising Stars';
        assignedTeams = ['Rising Stars'];
      } else if (email.contains('player')) {
        demoRole = 'player';
        demoId = 'demo_p_1';
        teamName = 'Thunder Squad';
        assignedTeams = ['Thunder Squad'];
      }

      final demoUser = UserModel(
        id: demoId,
        username: email.replaceFirst('demo_', '').split('@')[0].replaceAll('_', ' ').toUpperCase(),
        email: email,
        role: demoRole,
        teamName: teamName,
        assignedTeams: assignedTeams,
        profileCompleted: true,
        token: 'demo_token',
        position: demoRole == 'player' ? 'Point Guard' : null,
        stats: demoRole == 'player'
            ? {'matchesPlayed': 24, 'wins': 18, 'points': 485}
            : const {'matchesPlayed': 0, 'wins': 0, 'points': 0},
        rank: demoRole == 'player' ? 3 : 0,
      );

      Provider.of<ProfileViewmodel>(context, listen: false).setUser(demoUser);
      _setLoading(false);
      Navigator.pushNamedAndRemoveUntil(context, RouteNames.mainApp, (route) => false, arguments: demoUser.role);
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authRepository.login(email, password, role);
      Provider.of<ProfileViewmodel>(context, listen: false).setUser(user);
      _setLoading(false);
      
      if (user.profileCompleted) {
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
      
      // Success Dialog and Navigate to Login
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
