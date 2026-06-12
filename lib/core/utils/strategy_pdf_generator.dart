import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/strategy_model.dart';

class StrategyPdfGenerator {
  static Future<Uint8List> generate(StrategyModel strategy) async {
    final pdf = pw.Document();

    final meta = strategy.metadata ?? <String, dynamic>{};
    final rawSteps = meta['playSteps'];
    final playSteps = rawSteps is List
        ? rawSteps.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    
    final created = strategy.createdAt.toLocal();
    final dateLabel = '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('HOOPSTAR STRATEGY REPORT',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange800,
                          )),
                      pw.SizedBox(height: 4),
                      pw.Text(strategy.title.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          )),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(dateLabel, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(strategy.category.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Author Info
            pw.Row(
              children: [
                pw.Text('Created by: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('${strategy.createdByName} (${strategy.createdByRole})',
                    style: const pw.TextStyle(fontSize: 12)),
              ],
            ),

            pw.SizedBox(height: 30),

            // Breakdown Section
            pw.Text('STRATEGY BREAKDOWN',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
            pw.Divider(thickness: 1, color: PdfColors.orange100),
            pw.SizedBox(height: 10),
            pw.Paragraph(
              text: strategy.sourceText,
              style: const pw.TextStyle(fontSize: 12),
            ),

            pw.SizedBox(height: 30),

            // Key Plays Section
            if (playSteps.isNotEmpty) ...[
              pw.Text('KEY PLAYS & COACHING CUES',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
              pw.Divider(thickness: 1, color: PdfColors.orange100),
              pw.SizedBox(height: 10),
              ...List.generate(playSteps.length, (index) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 20,
                        child: pw.Text('${index + 1}.',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
                      ),
                      pw.Expanded(
                        child: pw.Text(playSteps[index], style: const pw.TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                );
              }),
            ],

            pw.SizedBox(height: 40),

            // Footer
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('© HoopStar Athletic Excellence', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Confidential Coaching Material', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
