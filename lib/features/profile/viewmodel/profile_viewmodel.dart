import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';

// Actually I don't have a UserRepository yet, but AuthRepository handles login. 
// I should create a UserRepository or ProfileRepository.
// I'll create ProfileRepository in the next step, so I will reference it here.
import '../../../core/repositories/profile_repository.dart';

class ProfileViewmodel extends ChangeNotifier {
  final ProfileRepository _profileRepository = ProfileRepository();
  
  UserModel? _user;
  UserModel? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadProfile({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_user != null && !forceRefresh) return;
    
    _setLoading(true);
    try {
      _user = await _profileRepository.getUserProfile();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  void clearProfile() {
    _user = null;
    notifyListeners();
  }

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
