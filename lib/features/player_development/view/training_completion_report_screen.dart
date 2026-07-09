import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ballchart/core/models/development_models.dart';
import 'package:ballchart/core/repositories/development_repository.dart';
import 'package:ballchart/core/utils/share_utils.dart';
import 'package:ballchart/features/player_development/player_development_theme.dart';

/// Full-screen module: preview and share the PDF for one completed training assignment.
class TrainingCompletionReportScreen extends StatefulWidget {
  const TrainingCompletionReportScreen({
    super.key,
    required this.assignment,
  });

  final TrainingAssignmentDto assignment;

  @override
  State<TrainingCompletionReportScreen> createState() => _TrainingCompletionReportScreenState();
}

class _TrainingCompletionReportScreenState extends State<TrainingCompletionReportScreen> {
  final DevelopmentRepository _repo = DevelopmentRepository();
  final GlobalKey _shareButtonKey = GlobalKey();
  Future<Uint8List>? _pdfFuture;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.assignment.status != 'completed') {
      _loadError = 'Complete the session first to generate a report.';
    } else {
      _pdfFuture = _repo.fetchAssignmentCompletionPdf(widget.assignment.id);
    }
  }

  Future<void> _share(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final name = 'training-completion-${widget.assignment.id}.pdf';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    await shareFiles(
      context,
      files: [XFile(file.path)],
      text: 'Training completion — ${widget.assignment.focusArea}',
      anchorKey: _shareButtonKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    return Scaffold(
      backgroundColor: PlayerDevelopmentTheme.bgColor,
      appBar: AppBar(
        backgroundColor: PlayerDevelopmentTheme.bgColor,
        elevation: 0,
        title: const Text(
          'COMPLETION REPORT',
          style: TextStyle(
            color: PlayerDevelopmentTheme.primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PlayerDevelopmentTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${a.focusArea} · ${a.drillName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '+${a.pointsValue} development points',
                    style: TextStyle(
                      color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.95),
                      fontSize: 13,
                    ),
                  ),
                  if (a.completedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Completed ${a.completedAt!.toLocal().toString().split('.').first}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                    ),
                  )
                : FutureBuilder<Uint8List>(
                    future: _pdfFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(color: PlayerDevelopmentTheme.primaryColor),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _pdfFuture = _repo.fetchAssignmentCompletionPdf(widget.assignment.id);
                                    });
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final bytes = snapshot.data;
                      if (bytes == null || bytes.isEmpty) {
                        return const Center(child: Text('Empty PDF', style: TextStyle(color: Colors.white54)));
                      }
                      return PdfPreview(
                        maxPageWidth: 520,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        allowPrinting: true,
                        allowSharing: false,
                        build: (format) async => bytes,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<Uint8List>(
                future: _pdfFuture,
                builder: (context, snap) {
                  final ready = snap.hasData && snap.data != null && snap.data!.isNotEmpty;
                  return FilledButton.icon(
                    key: _shareButtonKey,
                    style: FilledButton.styleFrom(
                      backgroundColor: PlayerDevelopmentTheme.primaryColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: ready ? () => _share(snap.data!) : null,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share PDF'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
