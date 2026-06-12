import 'package:flutter/material.dart';
import 'package:ballchart/core/models/notification_model.dart';
import 'package:ballchart/core/repositories/notification_repository.dart';

/// Opens the notifications bottom sheet (used from academy dashboard, coach home, player home).
Future<void> showNotificationPanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const NotificationPanel(),
  );
}

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  final NotificationRepository _repo = NotificationRepository();
  List<NotificationModel> notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchNotifications();
      if (mounted) {
        setState(() {
          notifications = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  int get _unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.52,
      minChildSize: 0.32,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1B1B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9D8F79),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'NOTIFICATIONS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Space Grotesk',
                        ),
                      ),
                    ),
                    if (_unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD900).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_unreadCount new',
                            style: const TextStyle(
                              color: Color(0xFFFFD900),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: _loading ? null : _markAllAsRead,
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          color: Color(0xFFFFD900),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFFFFD900)),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFF9D8F79), size: 40),
              const SizedBox(height: 12),
              Text(
                'Could not load notifications',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _load, child: const Text('Retry', style: TextStyle(color: Color(0xFFFFD900)))),
            ],
          ),
        ),
      );
    }
    if (notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF9D8F79),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(
                  color: Color(0xFF9D8F79),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationItem(notifications[index]);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead
            ? const Color(0xFF2A2A2A).withValues(alpha: 0.5)
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? Colors.transparent
              : const Color(0xFFFFD900).withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: const TextStyle(
                color: Color(0xFF9D8F79),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                color: const Color(0xFF9D8F79).withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD900),
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _markAsRead(notification),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'player_joined':
        return Colors.blue;
      case 'coach_added':
        return Colors.green;
      case 'team_created':
        return const Color(0xFFFFD900);
      case 'battle_scheduled':
        return Colors.orange;
      case 'strategy_added':
        return Colors.purple;
      case 'message_received':
        return const Color(0xFF4FC3F7);
      default:
        return const Color(0xFF9D8F79);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'player_joined':
        return Icons.person_add;
      case 'coach_added':
        return Icons.badge;
      case 'team_created':
        return Icons.group_add;
      case 'battle_scheduled':
        return Icons.sports_basketball;
      case 'strategy_added':
        return Icons.psychology;
      case 'message_received':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead || notification.id.isEmpty) return;
    try {
      await _repo.markRead(notification.id);
      if (!mounted) return;
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = notification.copyWith(isRead: true);
        }
      });
    } catch (_) {
      /* keep optimistic UI minimal; list refresh on next open */
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;
    try {
      await _repo.markAllRead();
      if (!mounted) return;
      setState(() {
        notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
    } catch (_) {
      await _load();
    }
  }
}
