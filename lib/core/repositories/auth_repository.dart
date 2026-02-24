import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<UserModel> login(String email, String password, String role) async {
    String endpoint = '/auth/coach/login';
    if (role == 'player') {
      endpoint = '/auth/player/login';
    } else if (role == 'admin') {
      endpoint = '/auth/admin/login';
    }

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

  Future<UserModel> signup(String username, String email, String password, String role, {String? academyName}) async {
    String endpoint = '/auth/coach/signup';
    if (role == 'player') {
      endpoint = '/auth/player/signup';
    } else if (role == 'admin') {
      endpoint = '/auth/admin/signup';
    }
    final response = await _apiService.post(endpoint, {
      'username': username,
      'email': email,
      'password': password,
      if (academyName != null) 'academyName': academyName,
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
