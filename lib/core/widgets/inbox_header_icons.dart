import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/features/inbox/viewmodel/inbox_viewmodel.dart';
import 'package:ballchart/features/messaging/view/conversations_list_screen.dart';
import 'package:ballchart/core/widgets/notification_panel.dart';

class MessagesIconButton extends StatelessWidget {
  const MessagesIconButton({
    super.key,
    this.iconColor = const Color(0xFFFFD900),
    this.iconSize = 26,
  });

  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<InboxViewModel>().unreadMessages;
    return IconButton(
      tooltip: 'Messages',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ConversationsListScreen()),
        );
        if (context.mounted) {
          context.read<InboxViewModel>().refresh();
        }
      },
      icon: _BadgedIcon(
        icon: Icons.chat_bubble_outline,
        color: iconColor,
        size: iconSize,
        badgeCount: unread,
      ),
    );
  }
}

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    this.iconColor = const Color(0xFFFFD900),
    this.iconSize = 26,
  });

  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<InboxViewModel>().unreadNotifications;
    return IconButton(
      tooltip: 'Notifications',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: () async {
        await showNotificationPanel(context);
        if (context.mounted) {
          context.read<InboxViewModel>().refresh();
        }
      },
      icon: _BadgedIcon(
        icon: Icons.notifications_none_rounded,
        color: iconColor,
        size: iconSize,
        badgeCount: unread,
        showDotOnly: unread > 0 && unread < 10,
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.badgeCount,
    this.showDotOnly = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final int badgeCount;
  final bool showDotOnly;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: size),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: showDotOnly
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD900),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF131313), width: 1.5),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD900),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF131313), width: 1),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}
