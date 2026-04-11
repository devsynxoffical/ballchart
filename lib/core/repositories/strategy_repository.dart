import '../models/strategy_model.dart';
import '../services/api_service.dart';

class StrategyRepository {
  final ApiService _apiService = ApiService();

  Future<List<StrategyModel>> getStrategies({
    String? category,
    String? tag,
    String? search,
    String? sortBy,
    int? limit,
    int? page,
  }) async {
    Map<String, String> queryParams = {};
    if (category != null) queryParams['category'] = category;
    if (tag != null) queryParams['tag'] = tag;
    if (search != null) queryParams['search'] = search;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (page != null) queryParams['page'] = page.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final endpoint = queryString.isNotEmpty 
        ? '/strategies?$queryString'
        : '/strategies';

    final response = await _apiService.get(endpoint);
    
    if (response is List) {
      return response
          .map((item) => StrategyModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } else if (response is Map && response['strategies'] != null) {
      return (response['strategies'] as List)
          .map((item) => StrategyModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<StrategyModel> createStrategy({
    required String title,
    required String category,
    required String sourceType,
    required String sourceText,
    String videoUrl = '',
    List<String>? tags,
    bool isPublic = true,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _apiService.post('/strategies', {
      'title': title,
      'category': category,
      'sourceType': sourceType,
      'sourceText': sourceText,
      'videoUrl': videoUrl,
      'tags': tags ?? [],
      'isPublic': isPublic,
      'metadata': metadata ?? {},
    });

    return StrategyModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<StrategyModel> updateStrategy(String id, {
    String? title,
    String? category,
    String? sourceText,
    String? videoUrl,
    List<String>? tags,
    bool? isPublic,
    Map<String, dynamic>? metadata,
  }) async {
    Map<String, dynamic> updateData = {};
    if (title != null) updateData['title'] = title;
    if (category != null) updateData['category'] = category;
    if (sourceText != null) updateData['sourceText'] = sourceText;
    if (videoUrl != null) updateData['videoUrl'] = videoUrl;
    if (tags != null) updateData['tags'] = tags;
    if (isPublic != null) updateData['isPublic'] = isPublic;
    if (metadata != null) updateData['metadata'] = metadata;

    final response = await _apiService.put('/strategies/$id', updateData);
    return StrategyModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteStrategy(String id) async {
    await _apiService.delete('/strategies/$id');
  }

  Future<StrategyModel> likeStrategy(String id) async {
    final response = await _apiService.post('/strategies/$id/like', {});
    return StrategyModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<StrategyModel> unlikeStrategy(String id) async {
    final response = await _apiService.delete('/strategies/$id/like');
    return StrategyModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<StrategyModel> incrementViewCount(String id) async {
    final response = await _apiService.post('/strategies/$id/view', {});
    return StrategyModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<List<String>> getCategories() async {
    final response = await _apiService.get('/strategies/categories');
    return (response as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  Future<List<String>> getTags() async {
    final response = await _apiService.get('/strategies/tags');
    return (response as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  Future<List<StrategyModel>> getMyStrategies() async {
    final response = await _apiService.get('/strategies/my');
    return (response as List?)
        ?.map((item) => StrategyModel.fromJson(Map<String, dynamic>.from(item)))
        .toList() ?? [];
  }

  Future<List<StrategyModel>> getPopularStrategies() async {
    final response = await _apiService.get('/strategies/popular');
    return (response as List?)
        ?.map((item) => StrategyModel.fromJson(Map<String, dynamic>.from(item)))
        .toList() ?? [];
  }

  Future<List<StrategyModel>> getRecentStrategies() async {
    final response = await _apiService.get('/strategies/recent');
    return (response as List?)
        ?.map((item) => StrategyModel.fromJson(Map<String, dynamic>.from(item)))
        .toList() ?? [];
  }
}
