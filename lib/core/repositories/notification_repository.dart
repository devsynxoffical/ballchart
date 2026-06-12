import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationRepository {
  final ApiService _api = ApiService();

  Future<List<NotificationModel>> fetchNotifications() async {
    final dynamic res = await _api.get('/notifications');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> markRead(String notificationId) async {
    await _api.patch('/notifications/$notificationId/read', {});
  }

  Future<void> markAllRead() async {
    await _api.patch('/notifications/read-all', {});
  }
}
