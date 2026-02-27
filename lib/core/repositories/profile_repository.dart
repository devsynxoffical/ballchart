import '../services/api_service.dart';
import '../models/user_model.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();

  Future<UserModel> getUserProfile() async {
    final response = await _apiService.get('/auth/profile');
    return UserModel.fromJson(response);
  }

  Future<void> completeProfile(Map<String, dynamic> profileData) async {
    await _apiService.put('/auth/profile', profileData);
  }
}
