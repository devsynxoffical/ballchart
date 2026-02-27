import '../services/api_service.dart';

class DashboardRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getCoachDashboard() async {
    final response = await _apiService.get('/auth/dashboard/coach');
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> getPlayerDashboard() async {
    final response = await _apiService.get('/auth/dashboard/player');
    return Map<String, dynamic>.from(response as Map);
  }
}
