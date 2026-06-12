import 'package:flutter/material.dart';
import 'package:ballchart/core/services/api_service.dart';

/// Network avatar with initials fallback — tuned for chat list / headers.
/// Uses [Image.network] (no sqflite) so avatars work after hot reload and on all targets.
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

  String get _initial {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ApiService.resolveMediaUrl(imageUrl);
    final bg = const Color(0xFF353534);
    final accent = const Color(0xFFFFD900);

    if (resolved.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: bg,
        child: Text(
          _initial,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
            fontSize: fontSize ?? size * 0.38,
          ),
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        resolved,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          final total = progress.expectedTotalBytes;
          final value = total != null && total > 0
              ? progress.cumulativeBytesLoaded / total
              : null;
          return Container(
            width: size,
            height: size,
            color: bg,
            alignment: Alignment.center,
            child: SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: value,
                color: accent.withValues(alpha: 0.7),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: size / 2,
          backgroundColor: bg,
          child: Text(
            _initial,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: fontSize ?? size * 0.38,
            ),
          ),
        ),
      ),
    );
  }
}
