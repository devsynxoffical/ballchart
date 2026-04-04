import '../models/battle_model.dart';
import '../services/api_service.dart';

class BattleRepository {
  final ApiService _apiService = ApiService();

  Future<List<BattleModel>> getBattles() async {
    final response = await _apiService.get('/battles');
    return (response as List).map((e) => BattleModel.fromJson(e)).toList();
  }

  Future<BattleModel> createBattle(String location, DateTime dateTime) async {
    final response = await _apiService.post('/battles', {
      'location': location,
      'dateTime': dateTime.toIso8601String(),
    });
    return BattleModel.fromJson(response);
  }

  Future<BattleModel> joinBattle(String battleId) async {
    final response = await _apiService.put('/battles/$battleId/join', {});
    return BattleModel.fromJson(response);
  }
}
