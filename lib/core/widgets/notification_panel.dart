import 'package:flutter/material.dart';
import 'package:ballchart/core/models/notification_model.dart';
import 'package:ballchart/core/constants/colors.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  List<NotificationModel> notifications = [];

  @override
  void initState() {
    super.initState();
    notifications = NotificationService.getMockNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B1B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF9D8F79),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NOTIFICATIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Space Grotesk',
                  ),
                ),
                TextButton(
                  onPressed: _markAllAsRead,
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
          
          // Notifications list
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: notifications.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
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
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? const Color(0xFF2A2A2A).withOpacity(0.5)
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead 
              ? Colors.transparent
              : const Color(0xFFFFD900).withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.2),
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
              style: TextStyle(
                color: const Color(0xFF9D8F79),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                color: const Color(0xFF9D8F79).withOpacity(0.7),
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

  void _markAsRead(NotificationModel notification) {
    setState(() {
      final index = notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        notifications[index] = notification.copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }
}
