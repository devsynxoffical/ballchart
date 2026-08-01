import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Square crop / calibration screen for profile photos.
/// User pans & zooms so the face sits in the yellow square, then saves.
class SquareImageCropScreen extends StatefulWidget {
  final File imageFile;

  const SquareImageCropScreen({super.key, required this.imageFile});

  @override
  State<SquareImageCropScreen> createState() => _SquareImageCropScreenState();
}

class _SquareImageCropScreenState extends State<SquareImageCropScreen> {
  static const Color _primary = Color(0xFFFFD900);
  static const Color _bg = Color(0xFF131313);

  final _boundaryKey = GlobalKey();
  final _transform = TransformationController();
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Crop preview not ready');
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Could not encode crop');
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final out = File(
        '${dir.path}/profile_crop_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await out.writeAsBytes(Uint8List.fromList(bytes), flush: true);
      if (!mounted) return;
      Navigator.pop(context, out);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Crop failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.sizeOf(context).width.clamp(240.0, 360.0);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text(
          'CALIBRATE PHOTO',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                  )
                : const Text('USE PHOTO', style: TextStyle(color: _primary, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(
              'Pinch to zoom and drag so your face sits inside the square.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: side,
                height: side,
                decoration: BoxDecoration(
                  border: Border.all(color: _primary, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: InteractiveViewer(
                      transformationController: _transform,
                      minScale: 1,
                      maxScale: 4,
                      constrained: false,
                      child: Image.file(
                        widget.imageFile,
                        width: side,
                        height: side,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
