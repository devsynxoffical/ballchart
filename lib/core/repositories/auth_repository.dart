import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<UserModel> login(
    String email,
    String password, {
    String? preferredRole,
  }) async {
    final roleToEndpoint = <String, String>{
      'admin': '/auth/admin/login',
      'coach': '/auth/coach/login',
      'player': '/auth/player/login',
      'assistant_coach': '/auth/coach/login',
      'head_coach': '/auth/coach/login',
    };

    final normalizedRole = preferredRole?.trim().toLowerCase();
    final String? preferredEndpoint =
        normalizedRole != null ? roleToEndpoint[normalizedRole] : null;

    final endpoints = <String>[
      if (preferredEndpoint != null) preferredEndpoint,
      '/auth/admin/login',
      '/auth/coach/login',
      '/auth/player/login',
    ].toSet().toList();

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
          try {
            final profile = await _apiService.get('/auth/profile');
            return UserModel.fromJson({
              ...response,
              ...profile,
              'token': user.token,
            });
          } catch (_) {
            // If profile fetch fails, continue with login payload.
          }
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
