import '../models/development_models.dart';

/// Aligns training assignments and period PDFs with the same core development areas.
/// Keep labels in sync with backend performance report constants.
abstract class RelentlessProgram {
  static const String title = 'Performance Report';
  static const String subtitle = 'Performance Development Program';
  static const String footerTagline = "Let's keep growing.";

  /// Shown on coach assign + player training screens.
  static const String trainingIntro =
      'Training sessions use the same development areas as your performance report and PDF (ratings, insights, goals). Pick a development area, then a drill.';

  static int get coreAreaCount => standardDevelopmentAreas.length;

  /// Standard areas (order matches PDF / backend).
  static const List<String> standardDevelopmentAreas = [
    'Technical Skills',
    'Shooting',
    'Strength & Conditioning',
    'Nutrition Awareness',
    'Mental Performance',
    'Attendance & Effort',
  ];

  /// Coach catalog may add extras; core areas first, then the rest (deduped).
  static List<String> mergedFocusOptions(List<String> catalogFocus) {
    final seen = <String>{};
    final out = <String>[];
    for (final a in standardDevelopmentAreas) {
      final t = a.trim();
      if (t.isEmpty) continue;
      if (seen.add(t)) out.add(t);
    }
    for (final x in catalogFocus) {
      final t = x.trim();
      if (t.isEmpty) continue;
      if (seen.add(t)) out.add(t);
    }
    return out;
  }

  static bool isStandardArea(String focus) {
    return standardDevelopmentAreas.contains(focus.trim());
  }

  /// Sort keys for grouping: standard order first, then alphabetical.
  static int compareAreaKeys(String a, String b) {
    final ia = standardDevelopmentAreas.indexOf(a.trim());
    final ib = standardDevelopmentAreas.indexOf(b.trim());
    if (ia != -1 && ib != -1) return ia.compareTo(ib);
    if (ia != -1) return -1;
    if (ib != -1) return 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  /// Ensures coaches always see all core areas, merging any saved API data.
  static List<PeriodReportAreaDto> mergeReportAreas(List<PeriodReportAreaDto> fromApi) {
    final byKey = {for (final a in fromApi) a.key: a};
    final byLabel = {for (final a in fromApi) a.label.trim().toLowerCase(): a};
    return standardDevelopmentAreas.asMap().entries.map((entry) {
      final label = entry.value;
      final key = 'area_${entry.key + 1}';
      return byKey[key] ??
          byLabel[label.toLowerCase()] ??
          PeriodReportAreaDto(key: key, label: label);
    }).toList();
  }
}
