import 'package:flutter/material.dart';

/// App-wide message popups (replaces bottom SnackBars).
enum AppMessageKind { error, success, info, warning }

class AppMessenger {
  static const Color _primary = Color(0xFFFFD900);
  static const Color _surface = Color(0xFF201F1F);
  static bool _dialogOpen = false;

  /// Preferred API for new call sites.
  static Future<void> show(
    BuildContext context, {
    required String message,
    AppMessageKind kind = AppMessageKind.info,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    // Prevent stacked success/error dialogs from flooding the UI.
    if (_dialogOpen) return;
    _dialogOpen = true;

    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: barrierDismissible,
        builder: (ctx) => _AppMessageDialog(
          message: trimmed,
          kind: kind,
          title: title ?? _defaultTitle(kind),
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      );
    } finally {
      _dialogOpen = false;
    }
  }

  /// Drop-in replacement for [ScaffoldMessengerState.showSnackBar].
  /// Converts SnackBar visuals into a centered BallChart popup.
  static void showSnackBar(BuildContext context, SnackBar snackBar) {
    if (!context.mounted) return;

    final message = _extractPlainText(snackBar.content).trim();
    if (message.isEmpty) return;

    final kind = _resolveKind(message, snackBar.backgroundColor);
    final action = snackBar.action;

    // Fire-and-forget; matches SnackBar async UX.
    // ignore: discarded_futures
    show(
      context,
      message: message,
      kind: kind,
      actionLabel: action?.label,
      onAction: action == null
          ? null
          : () {
              action.onPressed();
            },
    );
  }

  static String _defaultTitle(AppMessageKind kind) {
    switch (kind) {
      case AppMessageKind.error:
        return 'Error';
      case AppMessageKind.success:
        return 'Success';
      case AppMessageKind.warning:
        return 'Notice';
      case AppMessageKind.info:
        return 'Message';
    }
  }

  static AppMessageKind _resolveKind(String message, Color? color) {
    final fromMessage = _kindFromMessage(message);
    if (fromMessage != null) return fromMessage;
    return _kindFromColor(color);
  }

  static AppMessageKind? _kindFromMessage(String message) {
    final lower = message.toLowerCase();

    // Success signals first — avoids gold SnackBar backgrounds being read as errors.
    if (lower.contains('successfully') ||
        lower.contains('success') ||
        lower.contains(' saved') ||
        lower.startsWith('saved') ||
        lower.contains('copied') ||
        lower.contains('updated') ||
        lower.contains('joined') ||
        lower.contains('created') ||
        lower.contains('enrolled') ||
        lower.contains('password updated') ||
        lower.contains('verified') ||
        lower.contains('sent') ||
        lower.contains('complete')) {
      return AppMessageKind.success;
    }

    if (lower.startsWith('error') ||
        lower.startsWith('failed') ||
        lower.contains('could not') ||
        lower.contains('failure')) {
      return AppMessageKind.error;
    }

    if (lower.contains('please ') || lower.contains('must ') || lower.contains('enter ')) {
      return AppMessageKind.warning;
    }
    return null;
  }

  static AppMessageKind _kindFromColor(Color? color) {
    if (color == null) return AppMessageKind.info;
    final r = color.r;
    final g = color.g;
    final b = color.b;

    // BallChart gold / yellow → success (check before any red heuristic).
    if (r > 0.5 && g > 0.5 && b < 0.4) {
      return AppMessageKind.success;
    }
    // Greens → success
    if (g > r + 0.08 && g > b + 0.08) return AppMessageKind.success;
    // Reds → error (dominant red, not yellow)
    if (r > 0.6 && r > g + 0.2 && r > b + 0.2 && g < 0.5) return AppMessageKind.error;
    // Orange → warning
    if (r > 0.75 && g > 0.35 && g < 0.65 && b < 0.35) return AppMessageKind.warning;
    return AppMessageKind.info;
  }

  static String _extractPlainText(Widget? widget) {
    if (widget == null) return '';
    if (widget is Text) return widget.data ?? '';
    if (widget is RichText) {
      final span = widget.text;
      if (span is TextSpan) return span.toPlainText();
      return '';
    }
    if (widget is EditableText) return widget.controller.text;

    if (widget is Icon) return '';
    if (widget is SizedBox) {
      return _extractPlainText(widget.child);
    }
    if (widget is Padding) {
      return _extractPlainText(widget.child);
    }
    if (widget is Center) {
      return _extractPlainText(widget.child);
    }
    if (widget is Flexible) {
      return _extractPlainText(widget.child);
    }
    if (widget is Expanded) {
      return _extractPlainText(widget.child);
    }
    if (widget is Align) {
      return _extractPlainText(widget.child);
    }
    if (widget is DecoratedBox) {
      return _extractPlainText(widget.child);
    }
    if (widget is Container) {
      return _extractPlainText(widget.child);
    }
    if (widget is Row) {
      return widget.children.map(_extractPlainText).where((s) => s.trim().isNotEmpty).join(' ').trim();
    }
    if (widget is Column) {
      return widget.children.map(_extractPlainText).where((s) => s.trim().isNotEmpty).join(' ').trim();
    }
    if (widget is Wrap) {
      return widget.children.map(_extractPlainText).where((s) => s.trim().isNotEmpty).join(' ').trim();
    }
    return '';
  }
}

class _AppMessageDialog extends StatelessWidget {
  const _AppMessageDialog({
    required this.message,
    required this.kind,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppMessageKind kind;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  Color get _accent {
    switch (kind) {
      case AppMessageKind.error:
        return const Color(0xFFFF5252);
      case AppMessageKind.success:
        return const Color(0xFF4CAF50);
      case AppMessageKind.warning:
        return const Color(0xFFFF9800);
      case AppMessageKind.info:
        return AppMessenger._primary;
    }
  }

  IconData get _icon {
    switch (kind) {
      case AppMessageKind.error:
        return Icons.error_outline_rounded;
      case AppMessageKind.success:
        return Icons.check_circle_outline_rounded;
      case AppMessageKind.warning:
        return Icons.warning_amber_rounded;
      case AppMessageKind.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppMessenger._surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent.withValues(alpha: 0.35)),
                ),
                child: Icon(_icon, color: _accent, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (actionLabel != null && onAction != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          onAction!();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppMessenger._primary,
                          side: BorderSide(color: AppMessenger._primary.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          actionLabel!.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppMessenger._primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
