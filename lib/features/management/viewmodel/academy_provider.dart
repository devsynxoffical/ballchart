import 'package:flutter/foundation.dart';
import 'package:courtiq/core/models/local_academy_models.dart';
import 'package:courtiq/core/services/api_service.dart';

class AcademyProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  DummyUser? _currentUser;
  DummyUser? get currentUser => _currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;
  bool _hasLoadedOverview = false;

  String adminName = 'Academy Owner';
  String adminEmail = 'owner@academy.com';
  String adminPassword = 'admin123';

  Academy academy = Academy(
    id: 'a1',
    name: 'Elite Basketball Academy',
    logoUrl: null,
    teams: [],
    staff: [],
  );

  void loginByRole(String role) {
    _currentUser = DummyUser(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      name: adminName,
      role: role,
    );
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _hasLoadedOverview = false;
    notifyListeners();
  }

  Future<void> loadAdminOverview({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoadedOverview && !force) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/auth/admin/overview');
      final admin = (response['admin'] as Map<String, dynamic>? ?? {});
      final staffRaw = (response['staff'] as List<dynamic>? ?? []);
      final teamsRaw = (response['teams'] as List<dynamic>? ?? []);

      final mappedStaff = staffRaw
          .map((e) => _mapStaff(Map<String, dynamic>.from(e as Map)))
          .toList();
      final mappedTeams = teamsRaw
          .map((e) => _mapTeam(Map<String, dynamic>.from(e as Map)))
          .toList();

      academy = Academy(
        id: (admin['_id'] ?? 'a1').toString(),
        name: (admin['academyName'] ?? academy.name).toString(),
        logoUrl: admin['logoUrl']?.toString() ?? academy.logoUrl,
        teams: mappedTeams,
        staff: mappedStaff,
      );

      adminName = (admin['username'] ?? adminName).toString();
      adminEmail = (admin['email'] ?? adminEmail).toString();
      _hasLoadedOverview = true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Team _mapTeam(Map<String, dynamic> data) {
    final playersRaw = (data['players'] as List<dynamic>? ?? []);
    return Team(
      id: (data['_id'] ?? data['id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      ageGroup: (data['ageGroup'] ?? 'Open').toString(),
      colorValue: (data['colorValue'] is int) ? data['colorValue'] as int : 0xFFF59E0B,
      logoPath: data['logoPath']?.toString(),
      coachStaffId: data['coachStaffId']?.toString(),
      assistantCoachStaffId: data['assistantCoachStaffId']?.toString(),
      players: playersRaw
          .map((p) => _mapPlayer(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }

  Player _mapPlayer(Map<String, dynamic> data) {
    final ageText = (data['ageRange'] ?? '16').toString();
    final age = int.tryParse(RegExp(r'\d+').firstMatch(ageText)?.group(0) ?? '16') ?? 16;
    return Player(
      id: (data['_id'] ?? data['id'] ?? '').toString(),
      name: (data['username'] ?? data['name'] ?? '').toString(),
      position: (data['position'] ?? 'Guard').toString(),
      age: age,
    );
  }

  Staff _mapStaff(Map<String, dynamic> data) {
    final permissionsData = Map<String, dynamic>.from(
      (data['permissions'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    final assignedTeamIds = (data['assignedTeamIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return Staff(
      id: (data['_id'] ?? data['id'] ?? '').toString(),
      name: (data['username'] ?? data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      password: '',
      role: (data['role'] ?? 'coach').toString(),
      customRoleName: data['customRoleName']?.toString(),
      assignedTeamIds: assignedTeamIds,
      permissions: Permissions(
        createPlayer: permissionsData['createPlayer'] == true,
        readPlayer: permissionsData['readPlayer'] != false,
        updatePlayer: permissionsData['updatePlayer'] == true,
        deletePlayer: permissionsData['deletePlayer'] == true,
        createTeam: permissionsData['createTeam'] == true,
        manageStaff: permissionsData['manageStaff'] == true,
      ),
    );
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

  Future<void> addTeamToBackend(Team team) async {
    final response = await _apiService.post('/auth/team/create', {
      'name': team.name,
      'ageGroup': team.ageGroup,
      'colorValue': team.colorValue,
      if (team.logoPath != null && team.logoPath!.isNotEmpty) 'logoPath': team.logoPath,
    });
    addTeam(
      Team(
        id: (response['_id'] ?? nextId('t')).toString(),
        name: (response['name'] ?? team.name).toString(),
        ageGroup: (response['ageGroup'] ?? team.ageGroup).toString(),
        colorValue: (response['colorValue'] is int) ? response['colorValue'] as int : team.colorValue,
        logoPath: response['logoPath']?.toString(),
        players: const [],
      ),
    );
  }

  void updateTeam(Team updatedTeam) {
    final index = academy.teams.indexWhere((t) => t.id == updatedTeam.id);
    if (index == -1) return;
    academy.teams[index] = updatedTeam;
    notifyListeners();
  }

  Future<void> updateTeamInBackend(Team updatedTeam) async {
    final response = await _apiService.put('/auth/team/${updatedTeam.id}', {
      'name': updatedTeam.name,
      'ageGroup': updatedTeam.ageGroup,
      'colorValue': updatedTeam.colorValue,
      'logoPath': updatedTeam.logoPath,
    });

    updateTeam(
      Team(
        id: (response['_id'] ?? updatedTeam.id).toString(),
        name: (response['name'] ?? updatedTeam.name).toString(),
        players: updatedTeam.players,
        ageGroup: (response['ageGroup'] ?? updatedTeam.ageGroup).toString(),
        colorValue: (response['colorValue'] is int) ? response['colorValue'] as int : updatedTeam.colorValue,
        logoPath: response['logoPath']?.toString(),
        coachStaffId: updatedTeam.coachStaffId,
        assistantCoachStaffId: updatedTeam.assistantCoachStaffId,
      ),
    );
  }

  void deleteTeam(String teamId) {
    academy.teams.removeWhere((t) => t.id == teamId);
    for (final staff in academy.staff) {
      staff.assignedTeamIds.removeWhere((id) => id == teamId);
    }
    notifyListeners();
  }

  Future<void> deleteTeamInBackend(String teamId) async {
    await _apiService.delete('/auth/team/$teamId');
    deleteTeam(teamId);
  }

  void addPlayer(String teamId, Player player) {
    final team = academy.teams.firstWhere((t) => t.id == teamId);
    team.players.add(player);
    notifyListeners();
  }

  Future<void> addPlayerToBackend(
    String teamId,
    Player player, {
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post('/auth/player/create', {
      'username': player.name,
      'email': email,
      'password': password,
      'teamId': teamId,
      'position': player.position,
      'ageRange': '${player.age}',
    });
    addPlayer(
      teamId,
      Player(
        id: (response['_id'] ?? nextId('p')).toString(),
        name: (response['username'] ?? player.name).toString(),
        position: (response['position'] ?? player.position).toString(),
        age: player.age,
      ),
    );
  }

  void addStaff(Staff staff) {
    academy.staff.add(staff);
    notifyListeners();
  }

  Future<void> addStaffToBackend(Staff staff) async {
    final response = await _apiService.post('/auth/staff/create', {
      'username': staff.name,
      'email': staff.email,
      'password': staff.password,
      'role': staff.role,
      'customRoleName': staff.customRoleName,
      'assignedTeamIds': staff.assignedTeamIds,
      'permissions': {
        'createPlayer': staff.permissions.createPlayer,
        'readPlayer': staff.permissions.readPlayer,
        'updatePlayer': staff.permissions.updatePlayer,
        'deletePlayer': staff.permissions.deletePlayer,
        'createTeam': staff.permissions.createTeam,
        'manageStaff': staff.permissions.manageStaff,
      },
    });
    addStaff(
      Staff(
        id: (response['_id'] ?? nextId('s')).toString(),
        name: (response['username'] ?? staff.name).toString(),
        email: (response['email'] ?? staff.email).toString(),
        password: staff.password,
        role: (response['role'] ?? staff.role).toString(),
        customRoleName: response['customRoleName']?.toString() ?? staff.customRoleName,
        assignedTeamIds: (response['assignedTeamIds'] as List<dynamic>? ?? staff.assignedTeamIds)
            .map((e) => e.toString())
            .toList(),
        permissions: staff.permissions,
      ),
    );
    // Keep team lead labels in sync immediately after staff assignment changes.
    await loadAdminOverview(force: true);
  }

  void updateStaff(Staff updatedStaff) {
    final index = academy.staff.indexWhere((s) => s.id == updatedStaff.id);
    if (index == -1) return;
    academy.staff[index] = updatedStaff;
    notifyListeners();
  }

  Future<void> updateStaffInBackend(Staff updatedStaff) async {
    final response = await _apiService.put('/auth/staff/${updatedStaff.id}', {
      'username': updatedStaff.name,
      'email': updatedStaff.email,
      if (updatedStaff.password.isNotEmpty) 'password': updatedStaff.password,
      'role': updatedStaff.role,
      'customRoleName': updatedStaff.customRoleName,
      'assignedTeamIds': updatedStaff.assignedTeamIds,
      'permissions': {
        'createPlayer': updatedStaff.permissions.createPlayer,
        'readPlayer': updatedStaff.permissions.readPlayer,
        'updatePlayer': updatedStaff.permissions.updatePlayer,
        'deletePlayer': updatedStaff.permissions.deletePlayer,
        'createTeam': updatedStaff.permissions.createTeam,
        'manageStaff': updatedStaff.permissions.manageStaff,
      },
    });
    updateStaff(
      Staff(
        id: (response['_id'] ?? updatedStaff.id).toString(),
        name: (response['username'] ?? updatedStaff.name).toString(),
        email: (response['email'] ?? updatedStaff.email).toString(),
        password: updatedStaff.password,
        role: (response['role'] ?? updatedStaff.role).toString(),
        customRoleName: response['customRoleName']?.toString() ?? updatedStaff.customRoleName,
        assignedTeamIds: (response['assignedTeamIds'] as List<dynamic>? ?? updatedStaff.assignedTeamIds)
            .map((e) => e.toString())
            .toList(),
        permissions: updatedStaff.permissions,
      ),
    );
    // Backend may re-map coach/assistant team leads based on assigned teams.
    await loadAdminOverview(force: true);
  }

  void deleteStaff(String staffId) {
    academy.staff.removeWhere((s) => s.id == staffId);
    for (final team in academy.teams) {
      if (team.coachStaffId == staffId) team.coachStaffId = null;
      if (team.assistantCoachStaffId == staffId) team.assistantCoachStaffId = null;
    }
    notifyListeners();
  }

  Future<void> deleteStaffInBackend(String staffId) async {
    await _apiService.delete('/auth/staff/$staffId');
    deleteStaff(staffId);
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

  Future<void> updateAcademyProfileInBackend({
    required String academyName,
    String? logoUrl,
    required String ownerName,
    required String ownerEmail,
    String? newPassword,
  }) async {
    final response = await _apiService.put('/auth/admin/profile', {
      'academyName': academyName,
      'logoUrl': logoUrl,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      if (newPassword != null && newPassword.isNotEmpty) 'newPassword': newPassword,
    });

    updateAcademyProfile(
      academyName: (response['academyName'] ?? academyName).toString(),
      logoUrl: response['logoUrl']?.toString(),
      ownerName: (response['username'] ?? ownerName).toString(),
      ownerEmail: (response['email'] ?? ownerEmail).toString(),
      newPassword: newPassword,
    );
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

  Future<void> assignTeamLeadsInBackend({
    required String teamId,
    String? coachStaffId,
    String? assistantCoachStaffId,
  }) async {
    await _apiService.put('/auth/team/$teamId/leads', {
      'coachStaffId': coachStaffId,
      'assistantCoachStaffId': assistantCoachStaffId,
    });
    assignTeamLeads(
      teamId: teamId,
      coachStaffId: coachStaffId,
      assistantCoachStaffId: assistantCoachStaffId,
    );
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
