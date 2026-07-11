import 'package:flutter/foundation.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/core/services/api_service.dart';
import 'package:ballchart/core/models/user_model.dart';

class AcademyProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  /// Set only when [loadPlayerDashboard] fails (does not mix with admin/coach errors).
  String? _playerDashboardError;
  String? get playerDashboardError => _playerDashboardError;
  bool _hasLoadedOverview = false;

  /// After the first successful [loadAdminOverview], the dashboard should stay visible
  /// while refreshes/mutations run (those still set [isLoading] for progress, but UI must not
  /// replace the whole screen — see [AcademyDashboardScreen]).
  bool get hasLoadedAdminOverview => _hasLoadedOverview;
  
  Map<String, dynamic>? _coachDashboard;
  Map<String, dynamic>? get coachDashboard => _coachDashboard;
  
  Map<String, dynamic>? _playerDashboard;
  Map<String, dynamic>? get playerDashboard => _playerDashboard;

  bool _isCoachLoading = false;
  bool get isCoachLoading => _isCoachLoading;

  bool _isPlayerLoading = false;
  bool get isPlayerLoading => _isPlayerLoading;

  // Current user info from real authentication
  String _adminName = '';
  String get adminName => _currentUser?.username ?? _adminName;
  set adminName(String value) => _adminName = value;
  
  String _adminEmail = '';
  String get adminEmail => _currentUser?.email ?? _adminEmail;
  set adminEmail(String value) => _adminEmail = value;
  
  String _adminPassword = '';
  set adminPassword(String value) => _adminPassword = value;

  Academy academy = Academy(
    id: 'a1',
    name: 'Academy',
    logoUrl: null,
    teams: [],
    staff: [],
    battles: [],
  );

  // Set current user from authentication
  void setCurrentUser(UserModel user) {
    // Reset role-specific caches when session changes to avoid stale/unauthorized refresh calls.
    _cleanupSocketListeners();
    _hasLoadedOverview = false;
    _coachDashboard = null;
    _playerDashboard = null;
    _error = null;
    _playerDashboardError = null;
    _currentUser = user;
    notifyListeners();
  }

  // Legacy method for compatibility - remove role-based login
  @deprecated
  void loginByRole(String role) {
    // This method should not be used with real authentication
    throw Exception('Use proper authentication instead of role-based login');
  }

  void logout() {
    _cleanupSocketListeners();
    _currentUser = null;
    _hasLoadedOverview = false;
    _coachDashboard = null;
    _playerDashboard = null;
    _playerDashboardError = null;
    _apiService.clearToken();
    notifyListeners();
  }

  Future<void> loadAdminOverview({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoadedOverview && !force) return;

    // Check if user is authenticated
    final token = await _apiService.getToken();
    if (token == null) {
      _error = 'Not authenticated. Please log in again.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Loading admin overview with token: ${token.substring(0, 10)}...');
      final response = await _apiService.get('/auth/admin/overview');
      print('Admin overview response received: ${response.runtimeType}');
      
      // Clear existing data and load from backend
      academy.teams.clear();
      academy.staff.clear();
      academy.battles.clear();
      
      final admin = response['admin'] ?? {};
      final staffRaw = response['staff'] as List? ?? [];
      final teamsRaw = response['teams'] as List? ?? [];
      final battlesRaw = response['battles'] as List? ?? [];

      print('Processing ${staffRaw.length} staff, ${teamsRaw.length} teams, ${battlesRaw.length} battles');

      final mappedStaff = staffRaw.map((e) => _mapStaff(e)).toList();
      final mappedTeams = teamsRaw.map((e) => _mapTeam(e)).toList();
      final mappedBattles = battlesRaw.map((e) => _mapBattle(e)).toList();

      academy = Academy(
        id: (admin['_id'] ?? academy.id).toString(),
        name: (admin['academyName'] ?? academy.name).toString(),
        logoUrl: admin['logoUrl']?.toString() ?? academy.logoUrl,
        teams: mappedTeams,
        staff: mappedStaff,
        battles: mappedBattles,
      );
      
      adminName = (admin['username'] ?? _currentUser?.username).toString();
      adminEmail = (admin['email'] ?? _currentUser?.email).toString();
      
      _setupSocketListeners();
      _hasLoadedOverview = true;
      
      _isLoading = false;
      notifyListeners();
      print('Admin overview loaded successfully');
    } catch (e) {
      _isLoading = false;
      String errorMessage = e.toString();
      print('Error loading admin overview: $errorMessage');
      
      // Handle specific error cases
      if (errorMessage.contains('401') || errorMessage.contains('Unauthorized')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (errorMessage.contains('403') || errorMessage.contains('Forbidden')) {
        errorMessage = 'Access denied. You do not have permission to view this data.';
      } else if (errorMessage.contains('Cannot read properties of undefined')) {
        errorMessage = 'Connection error. Please check your internet connection.';
      } else if (errorMessage.contains('Network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
      }
      
      _error = 'Failed to load admin overview: $errorMessage';
      notifyListeners();
    }
  }

  Future<void> loadCoachDashboard({bool force = false}) async {
    if (_isCoachLoading) return;
    if (_coachDashboard != null && !force) return;

    _isCoachLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/auth/dashboard/coach');
      if (response is! Map) {
        throw Exception('Unexpected coach dashboard response');
      }
      _coachDashboard = Map<String, dynamic>.from(response);
      _setupSocketListeners();
    } catch (e) {
      _coachDashboard = null;
      _error = e.toString();
    } finally {
      _isCoachLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlayerDashboard({bool force = false}) async {
    if (_isPlayerLoading) return;
    if (_playerDashboard != null && !force) return;

    // Check if user is authenticated
    final token = await _apiService.getToken();
    if (token == null) {
      _playerDashboardError = 'Not authenticated. Please log in again.';
      notifyListeners();
      return;
    }

    _isPlayerLoading = true;
    _playerDashboardError = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        '/auth/dashboard/player',
        timeout: const Duration(seconds: 60),
      );

      final map = Map<String, dynamic>.from(response as Map);
      // Backend returns `profile`; player UI expects `player`.
      if (map.containsKey('profile')) {
        map['player'] = map['profile'];
      }
      _playerDashboard = map;
      _playerDashboardError = null;
      _setupSocketListeners();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('401') || errorMessage.contains('Unauthorized')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (errorMessage.contains('403') || errorMessage.contains('Forbidden')) {
        errorMessage = 'Access denied. You do not have permission to view player data.';
      } else if (errorMessage.contains('Cannot read properties of undefined')) {
        errorMessage = 'Connection error. Please check your internet connection.';
      } else if (errorMessage.contains('Network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (errorMessage.contains('timeout') || errorMessage.contains('Timeout')) {
        errorMessage = 'Request timed out. Check your connection and try again.';
      } else {
        errorMessage = errorMessage.replaceFirst(RegExp(r'^Exception:\s*'), '');
      }

      _playerDashboard = null;
      _playerDashboardError = errorMessage;
    } finally {
      _isPlayerLoading = false;
      notifyListeners();
    }
  }

  void _setupSocketListeners() {
    _apiService.connectSocket();
    final socket = _apiService.socket;
    if (socket == null || !socket.connected) return;

    // Clean up existing listeners first to prevent memory leaks
    _cleanupSocketListeners();

    // Helper to refresh if academy matches
    void refreshIfMatch(dynamic data) {
      // For Admin
      if (_hasLoadedOverview) {
        loadAdminOverview(force: true);
      }
      
      // For Coach
      if (_coachDashboard != null) {
        loadCoachDashboard(force: true);
      }

      // For Player
      if (_playerDashboard != null) {
        loadPlayerDashboard(force: true);
      }
    }

    socket.on('STAFF_CREATED', refreshIfMatch);
    socket.on('STAFF_UPDATED', refreshIfMatch);
    socket.on('STAFF_DELETED', refreshIfMatch);
    socket.on('TEAM_CREATED', refreshIfMatch);
    socket.on('TEAM_UPDATED', refreshIfMatch);
    socket.on('TEAM_DELETED', refreshIfMatch);
    socket.on('TEAM_LEADS_UPDATED', refreshIfMatch);
    socket.on('PLAYER_CREATED', refreshIfMatch);
    socket.on('PLAYER_UPDATED', refreshIfMatch);
    socket.on('PLAYER_DELETED', refreshIfMatch);
    
    socket.on('BATTLE_CREATED', (data) {
      loadAdminOverview(force: true);
      if (_coachDashboard != null) {
        loadCoachDashboard(force: true);
      }
    });
  }

  void _cleanupSocketListeners() {
    final socket = _apiService.socket;
    if (socket == null) return;

    final events = [
      'STAFF_CREATED', 'STAFF_UPDATED', 'STAFF_DELETED',
      'TEAM_CREATED', 'TEAM_UPDATED', 'TEAM_DELETED', 'TEAM_LEADS_UPDATED',
      'PLAYER_CREATED', 'PLAYER_UPDATED', 'PLAYER_DELETED',
      'BATTLE_CREATED'
    ];

    for (final event in events) {
      socket.off(event);
    }
  }

  /// Live player row for admin/coach profile screens (biometrics, averages, temp password).
  Future<Map<String, dynamic>?> fetchPlayerForStaff(String playerId) async {
    if (playerId.isEmpty) return null;
    try {
      final response = await _apiService.get('/auth/player/$playerId');
      if (response is Map<String, dynamic>) return response;
      if (response is Map) return Map<String, dynamic>.from(response);
      return null;
    } catch (e) {
      debugPrint('fetchPlayerForStaff: $e');
      return null;
    }
  }

  /// Staff for assign-lead UI: admin overview list, or coach dashboard `staff` when logged in as coach.
  List<Staff> getStaffListForAssignments() {
    if (academy.staff.isNotEmpty) return academy.staff;
    final raw = _coachDashboard?['staff'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map>()
        .map((e) => _mapStaff(Map<String, dynamic>.from(e)))
        .toList();
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
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final averages = data['averages'] as Map<String, dynamic>? ?? {};
    final rawPic = data['profileImageUrl']?.toString().trim();
    String? profileImageUrl;
    if (rawPic != null && rawPic.isNotEmpty) {
      profileImageUrl = ApiService.resolveMediaUrl(rawPic);
      if (profileImageUrl.isEmpty) profileImageUrl = null;
    }

    return Player(
      id: (data['_id'] ?? data['id'] ?? '').toString(),
      name: (data['username'] ?? data['name'] ?? '').toString(),
      email: (data['email'] ?? data['loginEmail'] ?? data['user']?['email'] ?? '').toString(),
      tempPassword: data['tempPassword']?.toString() ?? data['password']?.toString(),
      position: (data['position'] ?? 'Guard').toString(),
      age: age,
      matchesPlayed: stats['matchesPlayed'] ?? 0,
      wins: stats['wins'] ?? 0,
      points: stats['points'] ?? 0,
      height: (data['height'] ?? 'N/A').toString(),
      weight: (data['weight'] ?? 'N/A').toString(),
      wingspan: (data['wingspan'] ?? 'N/A').toString(),
      jerseyNumber: (data['jerseyNumber'] ?? 'N/A').toString(),
      scoutingNotes: (data['scoutingNotes'] ?? '').toString(),
      classYear: (data['classYear'] ?? 'N/A').toString(),
      isEliteProspect: data['isEliteProspect'] ?? false,
      ppg: (averages['ppg'] ?? 0.0).toDouble(),
      apg: (averages['apg'] ?? 0.0).toDouble(),
      rpg: (averages['rpg'] ?? 0.0).toDouble(),
      profileImageUrl: profileImageUrl,
    );
  }

  Battle _mapBattle(Map<String, dynamic> data) {
    return Battle(
      id: (data['_id'] ?? data['id'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      dateTime: DateTime.tryParse(data['dateTime']?.toString() ?? '') ?? DateTime.now(),
      status: (data['status'] ?? 'pending').toString(),
      result: data['result']?.toString(),
      hostId: data['host']?['_id']?.toString() ?? data['host']?.toString() ?? '',
      participantIds: (data['participants'] as List? ?? []).map((e) {
        if (e is Map) return (e['_id'] ?? '').toString();
        return e.toString();
      }).toList(),
    );
  }

  Staff _mapStaff(Map<String, dynamic> json) {
    return Staff(
      id: (json['_id'] ?? 's1').toString(),
      name: (json['username'] ?? 'Unnamed Staff').toString(),
      email: (json['email'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      role: (json['role'] ?? 'coach').toString(),
      customRoleName: json['customRoleName']?.toString(),
      profilePic: json['profilePic']?.toString(),
      assignedTeamIds: (json['assignedTeamIds'] as List? ?? json['assignedTeams'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      permissions: _mapPermissions(json['permissions']),
    );
  }

  Permissions _mapPermissions(Map<String, dynamic>? json) {
    if (json == null) {
      return Permissions(
        createPlayer: false,
        readPlayer: true,
        updatePlayer: false,
        deletePlayer: false,
        createTeam: false,
        manageStaff: false,
        createBattle: false,
        manageBattle: false,
        createStrategy: false,
        manageStrategy: false,
      );
    }
    return Permissions(
      createPlayer: json['createPlayer'] ?? false,
      readPlayer: json['readPlayer'] ?? true,
      updatePlayer: json['updatePlayer'] ?? false,
      deletePlayer: json['deletePlayer'] ?? false,
      createTeam: json['createTeam'] ?? false,
      manageStaff: json['manageStaff'] ?? false,
      createBattle: json['createBattle'] ?? false,
      manageBattle: json['manageBattle'] ?? false,
      createStrategy: json['createStrategy'] ?? false,
      manageStrategy: json['manageStrategy'] ?? false,
    );
  }

  UserModel? get currentStaff {
    if (_currentUser == null || !['coach', 'assistant_coach', 'head_coach'].contains(_currentUser!.role)) {
      return null;
    }
    return _currentUser;
  }

  // Check if current user has specific permission (honors admin-set flags on staff / JWT).
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;

    final role = _currentUser!.role.trim().toLowerCase();
    final profilePerms = _currentUser!.permissions;

    // Explicit permission map from /auth/profile — required for coach / assistant / head coach
    // so academy admins can revoke create battle, strategy, etc.
    if (profilePerms != null && profilePerms.isNotEmpty) {
      if (['coach', 'assistant_coach', 'head_coach'].contains(role)) {
        return Permissions.fromDynamic(profilePerms).hasPermission(permission);
      }
    }

    // Default role powers when the API has not sent a permission object yet
    if (role == 'admin' || role == 'head_coach') {
      return true;
    }

    if (role == 'coach' || role == 'assistant_coach') {
      final staff = academy.staff.firstWhere(
        (s) => s.email == _currentUser!.email,
        orElse: () => Staff(
          id: _currentUser!.id,
          name: _currentUser!.username,
          email: _currentUser!.email,
          password: '',
          role: _currentUser!.role,
          permissions: Permissions.forRole(_currentUser!.role),
        ),
      );
      return staff.permissions.hasPermission(permission);
    }

    return false;
  }

  // Get current user's permissions (same rules as [hasPermission]).
  Permissions get currentUserPermissions {
    if (_currentUser == null) return Permissions();

    final role = _currentUser!.role.trim().toLowerCase();
    final profilePerms = _currentUser!.permissions;

    if (profilePerms != null && profilePerms.isNotEmpty) {
      if (['coach', 'assistant_coach', 'head_coach'].contains(role)) {
        return Permissions.fromDynamic(profilePerms);
      }
    }

    if (role == 'admin' || role == 'head_coach') {
      return Permissions.forRole(role);
    }

    if (role == 'coach' || role == 'assistant_coach') {
      final staff = academy.staff.firstWhere(
        (s) => s.email == _currentUser!.email,
        orElse: () => Staff(
          id: _currentUser!.id,
          name: _currentUser!.username,
          email: _currentUser!.email,
          password: '',
          role: _currentUser!.role,
          permissions: Permissions.forRole(_currentUser!.role),
        ),
      );
      return staff.permissions;
    }

    return Permissions();
  }

  Team? get playerTeam {
    if (_currentUser == null || _currentUser!.role != 'player') {
      return null;
    }
    // Find team where current player is assigned
    for (final team in academy.teams) {
      if (team.players.any((p) => p.email == _currentUser!.email)) {
        return team;
      }
    }
    return academy.teams.isNotEmpty ? academy.teams.first : null;
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  void _showSuccessMessage(String message) {
    // This will be used to show success messages
    // Store the message for the UI to display
    _successMessage = message;
    notifyListeners();
  }

  String? _successMessage;
  String? get successMessage => _successMessage;

  void addTeam(Team team) {
    academy.teams.add(team);
    notifyListeners();
  }

  // Helper method to generate next ID
  String nextId(String prefix) {
    final existingIds = academy.teams.map((t) => t.id).toList();
    int maxId = 0;
    for (final id in existingIds) {
      try {
        final numId = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), ''));
        if (numId != null && numId > maxId) {
          maxId = numId;
        }
      } catch (e) {
        // Skip invalid IDs
      }
    }
    return '${prefix}${maxId + 1}';
  }

  // Helper method to get staff by ID
  Staff? getStaffById(String? staffId) {
    if (staffId == null || staffId.isEmpty) return null;
    try {
      return academy.staff.firstWhere((s) => s.id == staffId);
    } catch (_) {
      return null;
    }
  }

  // Helper method to update staff in backend
  Future<void> updateStaffInBackend(
    Staff updatedStaff, {
    bool refreshAfterUpdate = true,
    bool rethrowOnError = false,
  }) async {
    try {
      _clearError();
      
      final response = await _apiService.put('/auth/staff/${updatedStaff.id}', {
        'username': updatedStaff.name,
        'email': updatedStaff.email,
        if (updatedStaff.password != null && updatedStaff.password!.isNotEmpty)
          'password': updatedStaff.password,
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
          'createBattle': updatedStaff.permissions.createBattle,
          'manageBattle': updatedStaff.permissions.manageBattle,
          'createStrategy': updatedStaff.permissions.createStrategy,
          'manageStrategy': updatedStaff.permissions.manageStrategy,
        },
      });
      
      // Update local state immediately
      updateStaff(updatedStaff);
      _showSuccessMessage('Staff updated successfully!');
      
      // Refresh data from server when needed (avoid disruptive full refresh for small inline edits)
      if (refreshAfterUpdate) {
        await Future.delayed(const Duration(milliseconds: 500));
        await loadAdminOverview(force: true);
      }
      
    } catch (e) {
      String errorMessage = e.toString();
      print('Error updating staff: $errorMessage');
      
      // Handle specific error cases
      if (errorMessage.contains('401') || errorMessage.contains('Unauthorized')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (errorMessage.contains('403') || errorMessage.contains('Forbidden')) {
        errorMessage = 'Access denied. You do not have permission to update this staff.';
      } else if (errorMessage.contains('Cannot read properties of undefined')) {
        errorMessage = 'Connection error. The update may have succeeded. Please refresh.';
      } else if (errorMessage.contains('Network')) {
        errorMessage = 'Network error. The update may have succeeded. Please refresh.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Request timeout. The update may have succeeded. Please refresh.';
      }
      
      _setError('Failed to update staff: $errorMessage');
      
      if (rethrowOnError) {
        throw Exception(errorMessage);
      }
    }
  }

  // Helper method to assign team leads in backend
  Future<void> assignTeamLeadsInBackend({
    required String teamId,
    String? coachStaffId,
    String? assistantCoachStaffId,
  }) async {
    try {
      _clearError();
      
      await _apiService.put('/auth/team/$teamId/leads', {
        'coachStaffId': coachStaffId,
        'assistantCoachStaffId': assistantCoachStaffId,
      });
      
      assignTeamLeads(
        teamId: teamId,
        coachStaffId: coachStaffId,
        assistantCoachStaffId: assistantCoachStaffId,
      );

      if (_coachDashboard != null) {
        loadCoachDashboard(force: true);
      }
      if (_hasLoadedOverview) {
        loadAdminOverview(force: true);
      }

      _showSuccessMessage('Team leads assigned successfully!');
      notifyListeners();
    } catch (e) {
      _setError('Failed to assign team leads: ${e.toString()}');
    }
  }

  // Helper method to update academy profile in backend
  Future<void> updateAcademyProfileInBackend({
    required String academyName,
    String? logoUrl,
    required String ownerName,
    required String ownerEmail,
    String? newPassword,
  }) async {
    try {
      _clearError();
      
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
      
      _showSuccessMessage('Academy profile updated successfully!');
      notifyListeners();
    } catch (e) {
      _setError('Failed to update academy profile: ${e.toString()}');
    }
  }

  Future<void> addTeamToBackend(Team team) async {
    try {
      _clearError();
      
      final response = await _apiService.post('/auth/team/create', {
        'name': team.name,
        'ageGroup': team.ageGroup,
        'colorValue': team.colorValue,
        if (team.logoPath != null && team.logoPath!.isNotEmpty) 'logoPath': team.logoPath,
        if (team.coachStaffId != null) 'coachStaffId': team.coachStaffId,
        if (team.assistantCoachStaffId != null) 'assistantCoachStaffId': team.assistantCoachStaffId,
      });
      
      addTeam(
        Team(
          id: (response['_id'] ?? nextId('t')).toString(),
          name: (response['name'] ?? team.name).toString(),
          ageGroup: (response['ageGroup'] ?? team.ageGroup).toString(),
          colorValue: (response['colorValue'] is int) ? response['colorValue'] as int : team.colorValue,
          logoPath: response['logoPath']?.toString(),
          players: const [],
          coachStaffId: response['coachStaffId']?.toString() ?? team.coachStaffId,
          assistantCoachStaffId: response['assistantCoachStaffId']?.toString() ?? team.assistantCoachStaffId,
        ),
      );
      
      _showSuccessMessage('Team created successfully!');
      notifyListeners();
    } catch (e) {
      _setError('Failed to create team: ${e.toString()}');
    }
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
        email: (response['email'] ?? email).toString(),
        tempPassword: (response['tempPassword'] ?? password).toString(),
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
    try {
      _clearError();
      
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
          'createBattle': staff.permissions.createBattle,
          'manageBattle': staff.permissions.manageBattle,
          'createStrategy': staff.permissions.createStrategy,
          'manageStrategy': staff.permissions.manageStrategy,
        },
      });
      
      final savedPerms = Permissions.fromDynamic(response['permissions']);
      addStaff(
        Staff(
          id: (response['_id'] ?? nextId('s')).toString(),
          name: (response['username'] ?? staff.name).toString(),
          email: (response['email'] ?? staff.email).toString(),
          password: staff.password,
          role: (response['role'] ?? staff.role).toString(),
          customRoleName: response['customRoleName']?.toString() ?? staff.customRoleName,
          assignedTeamIds: (response['assignedTeamIds'] as List<dynamic>? ??
                  response['assignedTeams'] as List<dynamic>? ??
                  staff.assignedTeamIds)
              .map((e) => e.toString())
              .toList(),
          permissions: response['permissions'] != null ? savedPerms : staff.permissions,
        ),
      );
      
      _showSuccessMessage('Staff created successfully!');
      notifyListeners();
    } catch (e) {
      _setError('Failed to create staff: ${e.toString()}');
    }
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
    if (newPassword != null && newPassword.isNotEmpty) adminPassword = newPassword;
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
}
