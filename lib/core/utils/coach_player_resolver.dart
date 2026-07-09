import 'package:ballchart/features/management/viewmodel/academy_provider.dart';

/// Players a coach can assign training or generate reports for.
/// Prefers coach dashboard teams; falls back to academy overview teams.
List<MapEntry<String, String>> coachAssignablePlayers(AcademyProvider academy) {
  final seen = <String>{};
  final out = <MapEntry<String, String>>[];

  void addRaw(Map<dynamic, dynamic> p) {
    final id = (p['_id'] ?? p['id'] ?? '').toString();
    if (id.isEmpty || seen.contains(id)) return;
    seen.add(id);
    final name = p['username']?.toString() ?? p['name']?.toString() ?? 'Player';
    out.add(MapEntry(id, name));
  }

  final teams = academy.coachDashboard?['teams'] as List<dynamic>? ?? [];
  for (final t in teams) {
    if (t is! Map) continue;
    final players = t['players'] as List<dynamic>? ?? [];
    for (final p in players) {
      if (p is Map) addRaw(p);
    }
  }

  final dashPlayers = academy.coachDashboard?['players'] as List<dynamic>? ?? [];
  for (final p in dashPlayers) {
    if (p is Map) addRaw(p);
  }

  for (final team in academy.academy.teams) {
    for (final p in team.players) {
      if (p.id.isEmpty || seen.contains(p.id)) continue;
      seen.add(p.id);
      out.add(MapEntry(p.id, p.name.isNotEmpty ? p.name : 'Player'));
    }
  }

  out.sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
  return out;
}
