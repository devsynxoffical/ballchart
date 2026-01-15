import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<UserModel> login(String email, String password, String role) async {
    final endpoint = role == 'coach' ? '/auth/coach/login' : '/auth/player/login';
    final response = await _apiService.post(endpoint, {
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
    final endpoint = role == 'coach' ? '/auth/coach/signup' : '/auth/player/signup';
    final response = await _apiService.post(endpoint, {
      'username': username,
      'email': email,
      'password': password,
      // 'role': role, // schema defaults handle this, but can send if needed
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
