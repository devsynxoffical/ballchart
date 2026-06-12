/// Aligns training assignments and period PDFs with the same six development areas.
/// Keep labels in sync with [Backend/src/constants/relentlessDevelopmentReport.js].
abstract class RelentlessProgram {
  static const String title = 'Player Development Report';
  static const String subtitle = 'Performance Development Program';
  static const String footerTagline = "Let's keep growing.";

  /// Shown on coach assign + player training screens.
  static const String trainingIntro =
      'Training sessions use the same six development areas as the period report and PDF (ratings, insights, goals). Pick a development area, then a drill.';

  /// Standard areas (order matches PDF / backend).
  static const List<String> standardDevelopmentAreas = [
    'Technical Skills',
    'Shooting',
    'Strength & Conditioning',
    'Nutrition Awareness',
    'Mental Performance',
    'Attendance & Effort',
  ];

  /// Coach catalog may add extras; we always show Relentless six first, then the rest (deduped).
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
}
