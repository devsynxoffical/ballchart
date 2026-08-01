import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared "Exit App" confirmation used by every root screen
/// (coach, admin, player, login, auth).
Future<bool?> showAppExitDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF201F1F),
      title: const Text('Exit App', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Do you want to exit the application?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('No', style: TextStyle(color: Colors.white60)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Yes',
            style: TextStyle(color: Color(0xFFFFD900)),
          ),
        ),
      ],
    ),
  );
}

/// Blocks Android system back and iOS edge-swipe on the root screen.
///
/// Flow:
/// 1. [onBack] can consume the gesture (e.g. switch to home tab) — return `true`
/// 2. Otherwise show the exit dialog and close the app on confirm
///
/// On iOS, `PopScope(canPop: false)` disables the interactive pop gesture, so
/// a thin left-edge swipe zone triggers the same exit flow.
class AppExitScope extends StatefulWidget {
  const AppExitScope({
    super.key,
    required this.child,
    this.onBack,
  });

  final Widget child;

  /// Return `true` if the back press was handled (do not show exit dialog).
  final Future<bool> Function()? onBack;

  @override
  State<AppExitScope> createState() => _AppExitScopeState();
}

class _AppExitScopeState extends State<AppExitScope> {
  bool _handling = false;
  double _dragDx = 0;

  bool get _isCupertino {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  Future<void> _handleBackAttempt() async {
    if (_handling || !mounted) return;
    _handling = true;
    try {
      if (widget.onBack != null) {
        final handled = await widget.onBack!();
        if (handled || !mounted) return;
      }

      final shouldExit = await showAppExitDialog(context);
      if (shouldExit == true && mounted) {
        SystemNavigator.pop();
      }
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackAttempt();
      },
      child: widget.child,
    );

    if (!_isCupertino) return body;

    // Thin left-edge hit target — does not block scrolling in the main content.
    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 28,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _dragDx = 0,
            onHorizontalDragUpdate: (details) {
              if (details.delta.dx > 0) _dragDx += details.delta.dx;
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (_dragDx > 60 || velocity > 500) {
                _dragDx = 0;
                _handleBackAttempt();
              } else {
                _dragDx = 0;
              }
            },
          ),
        ),
      ],
    );
  }
}
