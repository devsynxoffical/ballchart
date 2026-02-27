import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<UserModel> login(String email, String password) async {
    final endpoints = <String>[
      '/auth/admin/login',
      '/auth/coach/login',
      '/auth/player/login',
    ];

    Exception? lastInvalidError;

    for (final endpoint in endpoints) {
      try {
        final response = await _apiService.post(endpoint, {
          'email': email,
          'password': password,
        });
        final user = UserModel.fromJson(response);
        if (user.token != null) {
          await _apiService.saveToken(user.token!);
        }
        return user;
      } catch (e) {
        final rawMessage = e.toString().replaceAll('Exception: ', '');
        final message = rawMessage.toLowerCase();
        final isInvalidCredential = message.contains('invalid admin credentials') ||
            message.contains('invalid coach credentials') ||
            message.contains('invalid player credentials');

        if (!isInvalidCredential) {
          rethrow;
        }
        lastInvalidError = Exception(rawMessage);
      }
    }

    throw lastInvalidError ?? Exception('Invalid credentials');
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
