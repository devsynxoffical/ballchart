import 'package:flutter/material.dart';
import 'package:ballchart/core/repositories/profile_repository.dart';
import '../../../../core/utils/user_friendly_errors.dart';
import '../../../../routes/routes_names.dart';
import 'package:provider/provider.dart';
import '../../../../features/profile/viewmodel/profile_viewmodel.dart';
import '../../../../core/widgets/custom_dialog.dart';

class ProfileSetupViewmodel extends ChangeNotifier {
  final ProfileRepository _profileRepository = ProfileRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // --- Coach Profile Data ---
  String? experienceLevel;
  List<String> sports = [];
  List<String> achievements = [];
  final TextEditingController coachAdditionalController = TextEditingController();

  void toggleSport(String sport) {
    if (sports.contains(sport)) {
      sports.remove(sport);
    } else {
      sports.add(sport);
    }
    notifyListeners();
  }

  void toggleAchievement(String achievement) {
    if (achievements.contains(achievement)) {
      achievements.remove(achievement);
    } else {
      achievements.add(achievement);
    }
    notifyListeners();
  }

  Future<void> completeCoachProfile(BuildContext context) async {
    if (experienceLevel == null || sports.isEmpty) {
      _showError(context, 'Please fill in all required fields (Experience Level and at least one sport).');
      return;
    }

    _setLoading(true);
    try {
      await _profileRepository.completeProfile({
        'experienceLevel': experienceLevel,
        'sports': sports,
        'achievements': achievements,
        'additionalInfo': coachAdditionalController.text.trim(),
      });
      _setLoading(false);
      // Refresh profile data in global state
      if (context.mounted) {
        final profileVm = Provider.of<ProfileViewmodel>(context, listen: false);
        await profileVm.loadProfile(forceRefresh: true);
        final updatedRole = profileVm.user?.role ?? 'coach';
        Navigator.pushNamedAndRemoveUntil(
          context, RouteNames.mainApp, (route) => false,
          arguments: updatedRole);
      }
    } catch (e) {
      _setLoading(false);
      final copy = resolveAuthDialogCopy(e, isSignup: false);
      if (context.mounted) {
        _showError(context, copy.message, title: copy.title);
      }
    }
  }

  // --- Player Profile Data ---
  String? position;
  String? ageRange;
  String? playerExperienceLevel;
  List<String> goals = [];
  final TextEditingController playerAdditionalGoalsController = TextEditingController();

  void toggleGoal(String goal) {
    if (goals.contains(goal)) {
      goals.remove(goal);
    } else {
      goals.add(goal);
    }
    notifyListeners();
  }

  Future<void> completePlayerProfile(BuildContext context) async {
    if (position == null || ageRange == null || playerExperienceLevel == null) {
      _showError(context, 'Please fill in all required fields (Position, Age Range, and Experience Level).');
      return;
    }

    _setLoading(true);
    try {
      await _profileRepository.completeProfile({
        'position': position,
        'ageRange': ageRange,
        'experienceLevel': playerExperienceLevel,
        'goals': goals,
        'additionalGoals': playerAdditionalGoalsController.text.trim(),
      });
      _setLoading(false);
      // Refresh profile data in global state
      if (context.mounted) {
        final profileVm = Provider.of<ProfileViewmodel>(context, listen: false);
        await profileVm.loadProfile(forceRefresh: true);
        final updatedRole = profileVm.user?.role ?? 'player';
        Navigator.pushNamedAndRemoveUntil(
          context, RouteNames.mainApp, (route) => false,
          arguments: updatedRole);
      }
    } catch (e) {
      _setLoading(false);
      final copy = resolveAuthDialogCopy(e, isSignup: false);
      if (context.mounted) {
        _showError(context, copy.message, title: copy.title);
      }
    }
  }

  void _showError(BuildContext context, String message, {String title = 'Error'}) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: title,
        message: message,
        isSuccess: false,
      ),
    );
  }

  @override
  void dispose() {
    coachAdditionalController.dispose();
    playerAdditionalGoalsController.dispose();
    super.dispose();
  }
}
