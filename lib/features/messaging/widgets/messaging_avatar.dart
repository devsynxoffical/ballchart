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
  });

  final String name;
  final String? imageUrl;
  final double size;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      name: name,
      imageUrl: imageUrl,
      size: size,
      fontSize: fontSize,
    );
  }
}
