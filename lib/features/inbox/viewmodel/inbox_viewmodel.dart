import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/messaging_models.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/repositories/messaging_repository.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/services/api_service.dart';

/// Tracks unread notifications and messages for header badges.
class InboxViewModel extends ChangeNotifier {
  final NotificationRepository _notificationRepo = NotificationRepository();
  final MessagingRepository _messagingRepo = MessagingRepository();
  final ApiService _api = ApiService();

  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  bool _started = false;

  int get unreadNotifications => _unreadNotifications;
  int get unreadMessages => _unreadMessages;
  int get totalUnread => _unreadNotifications + _unreadMessages;

  Timer? _pollTimer;
  void Function(dynamic)? _onMessageNew;
  void Function(dynamic)? _onNotificationNew;

  void start() {
    if (_started) return;
    _started = true;
    _api.connectSocket();
    _onMessageNew = (_) => refresh();
    _onNotificationNew = (_) => refresh();
    _api.socket?.on('MESSAGE_NEW', _onMessageNew!);
    _api.socket?.on('message:new', _onMessageNew!);
    _api.socket?.on('NOTIFICATION_NEW', _onNotificationNew!);
    _api.socket?.on('NOTIFICATION_CREATED', _onNotificationNew!);
    refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      final notifications = await _notificationRepo.fetchNotifications();
      final conversations = await _messagingRepo.fetchConversations();
      _unreadNotifications = notifications.where((n) => !n.isRead).length;
      _unreadMessages = conversations.fold<int>(
        0,
        (sum, ConversationSummary c) => sum + c.unreadCount,
      );
      notifyListeners();
    } catch (_) {
      /* keep last known counts */
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    if (_onMessageNew != null) {
      _api.socket?.off('MESSAGE_NEW', _onMessageNew);
      _api.socket?.off('message:new', _onMessageNew);
    }
    if (_onNotificationNew != null) {
      _api.socket?.off('NOTIFICATION_NEW', _onNotificationNew);
      _api.socket?.off('NOTIFICATION_CREATED', _onNotificationNew);
    }
    super.dispose();
  }
}
