import '../models/battle_model.dart';
import '../services/api_service.dart';

class BattleRepository {
  final ApiService _apiService = ApiService();

  Future<List<BattleModel>> getBattles({
    String? status,
    String? battleType,
    String? location,
    String? sortBy,
    int? limit,
    int? page,
    bool? myBattles,
  }) async {
    Map<String, String> queryParams = {};
    if (status != null) queryParams['status'] = status;
    if (battleType != null) queryParams['battleType'] = battleType;
    if (location != null) queryParams['location'] = location;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (page != null) queryParams['page'] = page.toString();
    if (myBattles != null) queryParams['myBattles'] = myBattles.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final endpoint = queryString.isNotEmpty 
        ? '/battles?$queryString'
        : '/battles';

    final response = await _apiService.get(endpoint);
    
    if (response is List) {
      return response
          .map((item) => BattleModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } else if (response is Map && response['battles'] != null) {
      return (response['battles'] as List)
          .map((item) => BattleModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<BattleModel> createBattle({
    required String location,
    required DateTime dateTime,
    String battleType = '1v1',
    int maxParticipants = 2,
    String? description,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _apiService.post('/battles', {
      'location': location,
      'dateTime': dateTime.toIso8601String(),
      'battleType': battleType,
      'maxParticipants': maxParticipants,
      'description': description,
      'tags': tags ?? [],
      'metadata': metadata ?? {},
    });

    return BattleModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<BattleModel> updateBattle(String id, {
    String? location,
    DateTime? dateTime,
    String? status,
    String? result,
    String? winnerId,
    String? description,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    Map<String, dynamic> updateData = {};
    if (location != null) updateData['location'] = location;
    if (dateTime != null) updateData['dateTime'] = dateTime.toIso8601String();
    if (status != null) updateData['status'] = status;
    if (result != null) updateData['result'] = result;
    if (winnerId != null) updateData['winnerId'] = winnerId;
    if (description != null) updateData['description'] = description;
    if (tags != null) updateData['tags'] = tags;
    if (metadata != null) updateData['metadata'] = metadata;

    final response = await _apiService.put('/battles/$id', updateData);
    return BattleModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteBattle(String id) async {
    await _apiService.delete('/battles/$id');
  }

  Future<BattleModel> joinBattle(String id) async {
    final response = await _apiService.put('/battles/$id/join', {});
    return BattleModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<BattleModel> leaveBattle(String id) async {
    final response = await _apiService.post('/battles/$id/leave', {});
    return BattleModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<BattleModel> startBattle(String id) async {
    final response = await _apiService.post('/battles/$id/start', {});
    return BattleModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<BattleModel> finishBattle(String id, {String? result, String? winnerId}) async {
    final response = await _apiService.post('/battles/$id/finish', {
      'result': result,
      'winnerId': winnerId,
    });
    return BattleModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<BattleModel> cancelBattle(String id) async {
    final response = await _apiService.post('/battles/$id/cancel', {});
    return BattleModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<BattleModel> incrementViewCount(String id) async {
    final response = await _apiService.post('/battles/$id/view', {});
    return BattleModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<List<String>> getLocations() async {
    final response = await _apiService.get('/battles/locations');
    return (response as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  Future<List<BattleModel>> getMyBattles() async {
    final response = await _apiService.get('/battles/my');
    return (response as List?)
        ?.map((item) => BattleModel.fromJson(Map<String, dynamic>.from(item)))
        .toList() ?? [];
  }

  Future<List<BattleModel>> getUpcomingBattles() async {
    final response = await _apiService.get('/battles/upcoming');
    return (response as List?)
        ?.map((item) => BattleModel.fromJson(Map<String, dynamic>.from(item)))
        .toList() ?? [];
  }

  Future<List<BattleModel>> getOngoingBattles() async {
    final response = await _apiService.get('/battles/ongoing');
    return (response as List?)
        ?.map((item) => BattleModel.fromJson(Map<String, dynamic>.from(item)))
        .toList() ?? [];
  }

  Future<List<BattleModel>> getFinishedBattles() async {
    final response = await _apiService.get('/battles/finished');
    return (response as List?)
        ?.map((item) => BattleModel.fromJson(Map<String, dynamic>.from(item)))
        .toList() ?? [];
  }

  Future<Map<String, dynamic>> getBattleStats() async {
    final response = await _apiService.get('/battles/stats');
    return Map<String, dynamic>.from(response as Map);
  }

  /// Phase 3 — append execution event (assist, turnover, etc.).
  Future<BattleModel> appendBattleEvent(
    String battleId, {
    required String type,
    Map<String, dynamic>? payload,
  }) async {
    final response = await _apiService.post('/battles/$battleId/events', {
      'type': type,
      'payload': payload ?? {},
    });
    return BattleModel.fromJson(Map<String, dynamic>.from(response));
  }
}
