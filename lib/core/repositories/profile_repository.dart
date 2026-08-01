import '../services/api_service.dart';
import '../models/user_model.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();

  Future<UserModel> getUserProfile() async {
    final response = await _apiService.get('/auth/profile');
    return UserModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Updates profile and returns the normalized user from the API.
  Future<UserModel> completeProfile(Map<String, dynamic> profileData) async {
    final response = await _apiService.put('/auth/profile', profileData);
    if (response is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(response));
    }
    return getUserProfile();
  }

  /// Verifies [oldPassword], then sets [newPassword].
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiService.put('/auth/change-password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> deleteMyAccount() async {
    await _apiService.post('/auth/account/delete', {
      'confirmPhrase': 'DELETE MY ACCOUNT',
    });
  }
}
