import '../services/api_service.dart';
import '../models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<UserModel> getUserProfile() async {
    // Assuming backend has an endpoint /auth/me or /users/profile
    // My backend routes: router.get('/me', protect, getMe); in authRoutes.js
    
    final response = await _apiService.get('/auth/me');
    return UserModel.fromJson(response);
  }

  Future<void> completeProfile(Map<String, dynamic> profileData) async {
    await _apiService.put('/auth/profile', profileData);
  }
}
