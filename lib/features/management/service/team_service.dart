import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';

class TeamService {
  final ApiService _apiService = ApiService();
  /// Same host as [ApiService.baseUrl] — `/api/teams` on Railway.
  String get _teamsBaseUrl => '${ApiService.baseUrl}/teams';

  Future<List<Map<String, dynamic>>> getManagedTeams() async {
    // Demo implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {'id': '1', 'name': 'Thunder Squad', 'description': 'Main Varsity Team'},
      {'id': '2', 'name': 'Rising Stars', 'description': 'Junior Varsity'},
    ];
  }

  Future<void> createTeam(String name, String description) async {
    // API logic here
  }

  Future<void> addPlayerToTeam(String teamId, String playerId) async {
     // API logic here
  }
}
