import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

/// In-app PDF viewer so report PDFs stay inside BallChart (no external browser).
class InAppPdfViewerScreen extends StatefulWidget {
  const InAppPdfViewerScreen({
    super.key,
    required this.url,
    this.title = 'PDF report',
  });

  final String url;
  final String title;

  @override
  State<InAppPdfViewerScreen> createState() => _InAppPdfViewerScreenState();
}

class _InAppPdfViewerScreenState extends State<InAppPdfViewerScreen> {
  static const Color _bg = Color(0xFF131313);
  static const Color _primary = Color(0xFFFFD900);

  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _load();
  }

  Future<Uint8List> _load() async {
    final res = await http.get(Uri.parse(widget.url));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Could not load PDF (HTTP ${res.statusCode})');
    }
    return res.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      ),
      body: FutureBuilder<Uint8List>(
        future: _bytesFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snap.error?.toString().replaceFirst('Exception: ', '') ??
                          'Could not open PDF',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _bytesFuture = _load()),
                      child: const Text('Retry', style: TextStyle(color: _primary)),
                    ),
                  ],
                ),
              ),
            );
          }
          final bytes = snap.data!;
          return PdfPreview(
            build: (_) async => bytes,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName: widget.title.endsWith('.pdf')
                ? widget.title
                : '${widget.title}.pdf',
          );
        },
      ),
    );
  }
}
