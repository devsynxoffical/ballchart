import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<UserModel> login(String email, String password) async {
    final response = await _apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });
    
    final user = UserModel.fromJson(response);
    if (user.token != null) {
      await _apiService.saveToken(user.token!);
    }
    return user;
  }

  Future<UserModel> signup(String username, String email, String password, String role) async {
    final response = await _apiService.post('/auth/signup', {
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    });

    final user = UserModel.fromJson(response);
    if (user.token != null) {
      await _apiService.saveToken(user.token!);
    }
    return user;
  }

  Future<void> logout() async {
    await _apiService.clearToken();
  }
}
