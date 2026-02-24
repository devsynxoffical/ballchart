import 'package:flutter/foundation.dart';
import 'package:courtiq/core/models/local_academy_models.dart';

class AcademyProvider extends ChangeNotifier {
  final List<DummyUser> dummyUsers = const [
    DummyUser(id: '1', name: 'Academy Owner', role: 'academy_owner'),
    DummyUser(id: '2', name: 'Main Coach', role: 'coach'),
    DummyUser(id: '3', name: 'Player One', role: 'player'),
  ];

  DummyUser? _currentUser;
  DummyUser? get currentUser => _currentUser;

  String adminName = 'Academy Owner';
  String adminEmail = 'owner@academy.com';
  String adminPassword = 'admin123';

  Academy academy = Academy(
    id: 'a1',
    name: 'Elite Basketball Academy',
    logoUrl: null,
    teams: [
      Team(
        id: 't1',
        name: 'Under 18',
        ageGroup: 'Under 18',
        colorValue: 0xFFF59E0B,
        players: [
          Player(id: 'p1', name: 'Ali', position: 'Guard', age: 17),
          Player(id: 'p2', name: 'Player One', position: 'Point Guard', age: 18),
        ],
        coachStaffId: 's1',
      ),
    ],
    staff: [
      Staff(
        id: 's1',
        name: 'Coach Ahmed',
        email: 'ahmed@academy.com',
        password: 'coach123',
        role: 'coach',
        permissions: Permissions(
          createPlayer: true,
          readPlayer: true,
          updatePlayer: true,
        ),
      ),
    ],
  );

  void loginByRole(String role) {
    _currentUser = dummyUsers.firstWhere((user) => user.role == role);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Staff? get currentStaff {
    if (_currentUser == null || _currentUser!.role != 'coach') {
      return null;
    }
    return academy.staff.isNotEmpty ? academy.staff.first : null;
  }

  Team? get playerTeam {
    if (_currentUser == null || _currentUser!.role != 'player') {
      return null;
    }
    for (final team in academy.teams) {
      if (team.players.any((p) => p.name == _currentUser!.name)) {
        return team;
      }
    }
    return academy.teams.isNotEmpty ? academy.teams.first : null;
  }

  void addTeam(Team team) {
    academy.teams.add(team);
    notifyListeners();
  }

  void addPlayer(String teamId, Player player) {
    final team = academy.teams.firstWhere((t) => t.id == teamId);
    team.players.add(player);
    notifyListeners();
  }

  void addStaff(Staff staff) {
    academy.staff.add(staff);
    notifyListeners();
  }

  void updateStaff(Staff updatedStaff) {
    final index = academy.staff.indexWhere((s) => s.id == updatedStaff.id);
    if (index == -1) return;
    academy.staff[index] = updatedStaff;
    notifyListeners();
  }

  void deleteStaff(String staffId) {
    academy.staff.removeWhere((s) => s.id == staffId);
    for (final team in academy.teams) {
      if (team.coachStaffId == staffId) team.coachStaffId = null;
      if (team.assistantCoachStaffId == staffId) team.assistantCoachStaffId = null;
    }
    notifyListeners();
  }

  void updateAcademyProfile({
    required String academyName,
    String? logoUrl,
    required String ownerName,
    required String ownerEmail,
    String? newPassword,
  }) {
    academy.name = academyName;
    academy.logoUrl = logoUrl;
    adminName = ownerName;
    adminEmail = ownerEmail;
    if (newPassword != null && newPassword.isNotEmpty) {
      adminPassword = newPassword;
    }
    notifyListeners();
  }

  void assignTeamLeads({
    required String teamId,
    String? coachStaffId,
    String? assistantCoachStaffId,
  }) {
    final team = academy.teams.firstWhere((t) => t.id == teamId);
    team.coachStaffId = coachStaffId;
    team.assistantCoachStaffId = assistantCoachStaffId;
    notifyListeners();
  }

  Staff? getStaffById(String? staffId) {
    if (staffId == null) return null;
    try {
      return academy.staff.firstWhere((s) => s.id == staffId);
    } catch (_) {
      return null;
    }
  }

  String nextId(String prefix) {
    return '$prefix${DateTime.now().microsecondsSinceEpoch}';
  }
}
