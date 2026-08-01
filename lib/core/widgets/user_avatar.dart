import 'package:flutter/material.dart';
import 'package:ballchart/core/services/api_service.dart';
import 'package:ballchart/core/utils/avatar_url.dart';

export 'package:ballchart/core/utils/avatar_url.dart' show pickAvatarUrl;

/// Shared BallChart profile avatar — resolves `/uploads/...` and falls back to initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.fontSize,
    this.borderColor,
    this.borderWidth = 0,
    this.backgroundColor = const Color(0xFF353534),
    this.accentColor = const Color(0xFFFFD900),
    this.usePersonIconFallback = false,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final double? fontSize;
  final Color? borderColor;
  final double borderWidth;
  final Color backgroundColor;
  final Color accentColor;
  /// When true, empty/error shows a person icon instead of a letter.
  final bool usePersonIconFallback;

  String get _initial {
    final t = name.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    if (parts.isEmpty) return '?';
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  Widget _fallback() {
    if (usePersonIconFallback) {
      return Container(
        width: size,
        height: size,
        color: backgroundColor,
        alignment: Alignment.center,
        child: Icon(Icons.person_outline_rounded, color: accentColor, size: size * 0.45),
      );
    }
    return Container(
      width: size,
      height: size,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          color: accentColor,
          fontWeight: FontWeight.w800,
          fontSize: fontSize ?? size * 0.36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ApiService.resolveMediaUrl(imageUrl);
    final hasUrl = resolved.isNotEmpty &&
        (resolved.startsWith('http://') ||
            resolved.startsWith('https://') ||
            resolved.startsWith('data:'));

    Widget child;
    if (!hasUrl) {
      child = ClipOval(child: _fallback());
    } else {
      child = ClipOval(
        child: Image.network(
          resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => _fallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              color: backgroundColor,
              alignment: Alignment.center,
              child: SizedBox(
                width: size * 0.32,
                height: size * 0.32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor.withValues(alpha: 0.7),
                ),
              ),
            );
          },
        ),
      );
    }

    if (borderWidth > 0 && borderColor != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: child,
      );
    }
    return SizedBox(width: size, height: size, child: child);
  }
}
