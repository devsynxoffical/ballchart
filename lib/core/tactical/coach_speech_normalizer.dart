/// Turns messy speech-to-text into coach-command text the local parser understands.
///
/// Examples:
/// - "player one passes to player two" → "P1 pass P2"
/// - "p 1 shoot" → "P1 shoot"
/// - "defender three screen" → "D3 screen"
String normalizeCoachSpeech(String input) {
  if (input.trim().isEmpty) return '';

  var s = input.toLowerCase().trim();

  // Strip punctuation that STT adds.
  s = s.replaceAll(RegExp(r'[.!?]+'), ' ');

  // Common basketball / STT mishearings.
  const mishearings = {
    'palyer': 'player',
    'palyar': 'player',
    'playar': 'player',
    'playur': 'player',
    'payler': 'player',
    'plater': 'player',
    'playa': 'player',
    'plaer': 'player',
    'defence': 'defense',
    'defender': 'defense',
    'defenders': 'defense',
    'offence': 'offense',
    'passed': 'pass',
    'passes': 'pass',
    'passing': 'pass',
    'past': 'pass',
    'path': 'pass',
    'parse': 'pass',
    'pause': 'pass',
    'through': 'to',
    'shoots': 'shoot',
    'shooting': 'shoot',
    'shot': 'shoot',
    'scores': 'shoot',
    'screening': 'screen',
    'screens': 'screen',
    'picked': 'pick',
    'picks': 'pick',
    'moves': 'move',
    'moving': 'move',
    'cuts': 'cut',
    'cutting': 'cut',
    'runs': 'run',
    'running': 'run',
    'rolls': 'roll',
    'rolling': 'roll',
    'drives': 'drive',
    'driving': 'drive',
  };
  for (final e in mishearings.entries) {
    s = s.replaceAll(RegExp('\\b${RegExp.escape(e.key)}\\b'), e.value);
  }

  // Spoken numbers → digits (before player/defense patterns).
  const wordNumbers = {
    'zero': '0',
    'oh': '0',
    'one': '1',
    'won': '1',
    'two': '2',
    'to': '2', // only when sandwiched — handled below; skip global 'to'
    'too': '2',
    'three': '3',
    'tree': '3',
    'free': '3',
    'four': '4',
    'for': '4',
    'fore': '4',
    'five': '5',
  };

  // Replace "player one" style before bare word → digit.
  for (final e in wordNumbers.entries) {
    if (e.key == 'to') continue;
    s = s.replaceAllMapped(
      RegExp('\\b(player|number|offense|defense|p|o|d)\\s+${RegExp.escape(e.key)}\\b'),
      (m) => '${m[1]} ${e.value}',
    );
  }

  // Bare spoken digits in actor context: "player one" already handled; now global word nums.
  for (final e in wordNumbers.entries) {
    if (e.key == 'to') continue;
    s = s.replaceAll(RegExp('\\b${RegExp.escape(e.key)}\\b'), e.value);
  }

  // Collapse "pass 2" after player when STT drops "to": "p1 pass 2" → "p1 pass p2"
  s = s.replaceAllMapped(
    RegExp(r'\b([pod])\s*([1-5])\s+(pass|handoff|give|throw)\s+([1-5])\b'),
    (m) => '${m[1]}${m[2]} ${m[3]} ${m[1]}${m[4]}',
  );

  // Actor shorthand: player/number/offense → P, defense → D
  s = s.replaceAllMapped(
    RegExp(r'\b(?:player|number|offense)\s*([1-5])\b'),
    (m) => 'p${m[1]}',
  );
  s = s.replaceAllMapped(
    RegExp(r'\bdefense\s*([1-5])\b'),
    (m) => 'd${m[1]}',
  );
  s = s.replaceAllMapped(RegExp(r'\b([pod])\s+([1-5])\b'), (m) => '${m[1]}${m[2]}');

  // Remove filler words.
  s = s.replaceAll(RegExp(r'\b(to|the|a|an|at|on|up|down|please|now|then)\b'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Uppercase actor tokens for readability: p1 → P1
  s = s.replaceAllMapped(RegExp(r'\b([pod])([1-5])\b'), (m) => '${m[1]!.toUpperCase()}${m[2]}');

  return s;
}

/// User-facing hint after voice capture.
String coachSpeechHint(String normalized) {
  if (normalized.isEmpty) return 'Say e.g. "Player one pass player two" or "P1 shoot"';
  return 'Heard: $normalized';
}
