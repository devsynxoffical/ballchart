/// Basketball-only strategy vocabulary (plays, categories, tags).
/// Keep in sync with [Backend/src/constants/basketballStrategy.js].
abstract class BasketballStrategy {
  static const List<String> categories = [
    'offense',
    'defense',
    'transition',
    'inbound',
    'press',
    'drills',
  ];

  static const List<String> suggestedTags = [
    'half court',
    'transition',
    'zone',
    'man-to-man',
    'press',
    'ATO',
    'BLOB',
    'SLOB',
    'pick-and-roll',
    'spacing',
    'shooting',
    'closeout',
  ];

  static const List<String> commonPlays = [
    'Horns pick-and-roll',
    'Spread ball screen',
    'Floppy / stagger',
    'DHO (dribble hand-off)',
    'Spain pick-and-roll',
    'Zone 2-3 overload',
    'Man-to-man shell',
    'Full-court press',
    'Press break',
    'Transition lane fill',
    'BLOB baseline',
    'SLOB sideline',
    'Hammer action',
    'Spain P&R',
    'Flex screen',
  ];

  static String categoryLabel(String id) {
    switch (id.toLowerCase()) {
      case 'offense':
        return 'Offense';
      case 'defense':
        return 'Defense';
      case 'transition':
        return 'Transition';
      case 'inbound':
        return 'Inbound / ATO';
      case 'press':
        return 'Press';
      case 'drills':
        return 'Skill drills';
      case 'general':
        return 'Transition';
      default:
        if (id.isEmpty) return 'All';
        return id[0].toUpperCase() + id.substring(1);
    }
  }

  static String normalizeCategory(String? raw) {
    final id = (raw ?? '').trim().toLowerCase();
    if (categories.contains(id)) return id;
    if (id == 'general') return 'transition';
    return 'offense';
  }
}
