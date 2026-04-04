import '../models/strategy_model.dart';
import '../services/api_service.dart';

class StrategyRepository {
  final ApiService _apiService = ApiService();

  Future<List<StrategyModel>> getStrategies() async {
    final response = await _apiService.get('/strategies');
    return (response as List)
        .map((item) => StrategyModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<StrategyModel> createStrategy({
    required String title,
    required String category,
    required String sourceType,
    required String sourceText,
    required String videoUrl,
  }) async {
    final response = await _apiService.post('/strategies', {
      'title': title,
      'category': category,
      'sourceType': sourceType,
      'sourceText': sourceText,
      'videoUrl': videoUrl,
    });

    return StrategyModel.fromJson(Map<String, dynamic>.from(response));
  }
}
