import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  bool _socketAttached = false;

  void start() {
    if (_started) return;
    _started = true;
    _onMessageNew = (_) => refresh();
    _onNotificationNew = (_) => refresh();
    // connectSocket() is async, so register handlers through the callback —
    // they fire the moment the socket connects (fixes missed real-time events).
    _api.onSocketConnect(_attachSocketHandlers);
    _api.connectSocket();
    refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => refresh());
  }

  void _attachSocketHandlers(IO.Socket s) {
    if (_socketAttached) return;
    _socketAttached = true;
    s.on('MESSAGE_NEW', _onMessageNew!);
    s.on('message:new', _onMessageNew!);
    s.on('NOTIFICATION_NEW', _onNotificationNew!);
    s.on('NOTIFICATION_CREATED', _onNotificationNew!);
  }

  Future<void> refresh() async {
    try {
      final notifications = await _notificationRepo.fetchNotifications();
      final conversations = await _messagingRepo.fetchConversations();

      bool isMessageNotif(NotificationModel n) {
        final t = n.type.toLowerCase();
        return t.contains('message') || t == 'chat';
      }

      // Bell = non-message actions only. Chat icon handles message unread.
      _unreadNotifications =
          notifications.where((n) => !n.isRead && !isMessageNotif(n)).length;

      // Message icon = conversation unread only (clears when chats are opened/seen).
      // Do not keep the dot from message notifications — those can lag after mark-read.
      _unreadMessages = conversations.fold<int>(
        0,
        (sum, ConversationSummary c) => sum + c.unreadCount,
      );
      notifyListeners();
    } catch (_) {
      /* keep last known counts */
    }
  }

  /// Optimistically clear the chat badge (e.g. right after opening/reading a thread).
  void clearMessageBadge() {
    if (_unreadMessages == 0) return;
    _unreadMessages = 0;
    notifyListeners();
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
