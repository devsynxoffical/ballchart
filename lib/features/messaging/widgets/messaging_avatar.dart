import 'package:flutter/material.dart';
import 'package:ballchart/core/widgets/user_avatar.dart';

/// Network avatar with initials fallback — tuned for chat list / headers.
class MessagingAvatar extends StatelessWidget {
  const MessagingAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.fontSize,
    this.isOnline = false,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final double? fontSize;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final avatar = UserAvatar(
      name: name,
      imageUrl: imageUrl,
      size: size,
      fontSize: fontSize,
    );
    if (!isOnline) return avatar;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF131313), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
