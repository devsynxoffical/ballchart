import '../../../core/services/api_service.dart';

class StaffService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
    String? teamId,
  }) async {
    try {
      final response = await _apiService.post('/auth/staff/create', {
        'username': name,
        'email': email,
        'password': password,
        'role': role,
        if (teamId != null) 'teamId': teamId,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPlayer({
    required String name,
    required String email,
    required String password,
    String? number,
    String? position,
    String? height,
    String? weight,
  }) async {
    try {
      final response = await _apiService.post('/auth/player/create', {
        'username': name,
        'email': email,
        'password': password,
        'number': number,
        'position': position,
        'height': height,
        'weight': weight,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getStaffCredentials() async {
    try {
      final response = await _apiService.get('/staff/credentials');
      return response as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
