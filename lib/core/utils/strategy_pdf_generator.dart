import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../constants/basketball_strategy.dart';
import '../models/strategy_model.dart';

/// Professional BallChart strategy / playbook PDF export.
class StrategyPdfGenerator {
  static const PdfColor _ink = PdfColor.fromInt(0xFF111111);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B6B6B);
  static const PdfColor _soft = PdfColor.fromInt(0xFF9A9A9A);
  static const PdfColor _line = PdfColor.fromInt(0xFFE6E6E6);
  static const PdfColor _card = PdfColor.fromInt(0xFFF6F6F6);
  static const PdfColor _header = PdfColor.fromInt(0xFF141414);
  static const PdfColor _gold = PdfColor.fromInt(0xFFFFD900);
  static const PdfColor _goldDark = PdfColor.fromInt(0xFFC9A600);

  /// Strip / replace characters that Helvetica cannot encode (avoids PDF failures).
  static String _safe(dynamic value, {String fallback = '—'}) {
    var s = (value ?? '').toString().trim();
    if (s.isEmpty) return fallback;
    s = s
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2026', '...')
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '');
    // Keep printable Latin + common punctuation; drop other unicode that breaks Helvetica.
    s = s.replaceAll(RegExp(r'[^\x09\x0A\x0D\x20-\x7E]'), '');
    s = s.replaceAll(RegExp(r'[ \t]+\n'), '\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return s.isEmpty ? fallback : s;
  }

  static String _roleLabel(String role) {
    final r = role.trim().toLowerCase();
    if (r.isEmpty) return 'Coach';
    return r
        .split('_')
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  static List<String> _playSteps(Map<String, dynamic> meta) {
    final raw = meta['playSteps'];
    if (raw is! List) return const [];
    return raw
        .map((e) => _safe(e, fallback: ''))
        .where((e) => e.isNotEmpty && e != '—')
        .toList();
  }

  static Future<Uint8List> generate(StrategyModel strategy) async {
    final pdf = pw.Document(
      title: 'BallChart Strategy — ${_safe(strategy.title)}',
      author: 'BallChart',
      creator: 'BallChart',
      subject: 'Strategy playbook report',
    );

    final meta = strategy.metadata ?? <String, dynamic>{};
    final playSteps = _playSteps(meta);
    final title = _safe(strategy.title, fallback: 'Untitled Strategy');
    final category = _safe(
      BasketballStrategy.categoryLabel(strategy.category),
      fallback: _safe(strategy.category),
    );
    final sourceType = _safe(strategy.sourceType, fallback: 'text').toUpperCase();
    final createdBy = _safe(strategy.createdByName, fallback: 'Coach');
    final role = _roleLabel(strategy.createdByRole);
    final body = _safe(strategy.sourceText, fallback: 'No strategy breakdown provided.');
    final videoUrl = _safe(strategy.videoUrl, fallback: '');
    final tags = strategy.tags
        .map((t) => _safe(t, fallback: ''))
        .where((t) => t.isNotEmpty && t != '—')
        .toList();

    final created = strategy.createdAt.toLocal();
    final dateLabel =
        '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 48),
        header: (context) => _pageHeader(context),
        footer: (context) => _pageFooter(context),
        build: (context) => [
          _heroBanner(title: title, category: category, dateLabel: dateLabel),
          pw.SizedBox(height: 18),
          _metaRow(
            items: [
              MapEntry('Created by', '$createdBy · $role'),
              MapEntry('Source', sourceType),
              MapEntry('Views', '${strategy.viewCount}'),
            ],
          ),
          pw.SizedBox(height: 22),
          _sectionTitle('STRATEGY BREAKDOWN'),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _card,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _line, width: 0.8),
            ),
            child: pw.Text(
              body,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 3.2, color: _ink),
            ),
          ),
          if (playSteps.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            _sectionTitle('KEY PLAYS & COACHING CUES'),
            pw.SizedBox(height: 10),
            ...List.generate(playSteps.length, (i) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 22,
                      height: 22,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: _gold,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        '${i + 1}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 3),
                        child: pw.Text(
                          playSteps[i],
                          style: const pw.TextStyle(fontSize: 11, lineSpacing: 2.8, color: _ink),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (videoUrl.isNotEmpty && videoUrl != '—') ...[
            pw.SizedBox(height: 22),
            _sectionTitle('REFERENCE VIDEO'),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _line, width: 0.8),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                videoUrl,
                style: const pw.TextStyle(fontSize: 10, color: _muted),
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            _sectionTitle('TAGS'),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (t) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: _card,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: _line, width: 0.7),
                      ),
                      child: pw.Text(
                        t,
                        style: const pw.TextStyle(fontSize: 9, color: _ink),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          pw.SizedBox(height: 28),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _header,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BALLCHART',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _gold,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Confidential coaching material. For authorized academy staff and players only.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pageHeader(pw.Context context) {
    if (context.pageNumber == 1) return pw.SizedBox();
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'BALLCHART  ·  STRATEGY REPORT',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
                letterSpacing: 0.8,
              ),
            ),
            pw.Container(width: 36, height: 3, color: _gold),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _line, thickness: 0.6),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _pageFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: _line, thickness: 0.6),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'BallChart',
              style: const pw.TextStyle(fontSize: 8, color: _soft),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _soft),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _heroBanner({
    required String title,
    required String category,
    required String dateLabel,
  }) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: _header,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 4, color: _gold),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BALLCHART STRATEGY REPORT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _gold,
                    letterSpacing: 1.4,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    lineSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    _pill(category.toUpperCase(), filled: true),
                    pw.SizedBox(width: 8),
                    _pill(dateLabel, filled: false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pill(String text, {required bool filled}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: filled ? _gold : null,
        borderRadius: pw.BorderRadius.circular(4),
        border: filled ? null : pw.Border.all(color: PdfColors.grey600, width: 0.7),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: filled ? _ink : PdfColors.grey400,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  static pw.Widget _metaRow({required List<MapEntry<String, String>> items}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              pw.Container(
                width: 1,
                height: 28,
                margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                color: _line,
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    items[i].key.toUpperCase(),
                    style: const pw.TextStyle(fontSize: 7.5, color: _soft, letterSpacing: 0.8),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    items[i].value,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(width: 3, height: 12, color: _goldDark),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
