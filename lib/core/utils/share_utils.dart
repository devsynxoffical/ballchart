import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// iPad (and some iOS layouts) require a non-zero origin for the share popover.
Rect shareOriginFor(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    final origin = box.localToGlobal(Offset.zero) & box.size;
    if (origin.width > 0 && origin.height > 0) return origin;
  }
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height * 0.85),
    width: 2,
    height: 2,
  );
}

Future<void> shareFiles(
  BuildContext context, {
  required List<XFile> files,
  String? text,
  String? subject,
  GlobalKey? anchorKey,
}) {
  final anchorCtx = anchorKey?.currentContext;
  final originCtx = (anchorCtx != null && anchorCtx.mounted) ? anchorCtx : context;
  return Share.shareXFiles(
    files,
    text: text,
    subject: subject,
    sharePositionOrigin: shareOriginFor(originCtx),
  );
}
