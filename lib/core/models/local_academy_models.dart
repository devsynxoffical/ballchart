class Academy {
  String id;
  String name;
  String? logoUrl;
  List<Team> teams;
  List<Staff> staff;
  List<Battle> battles;

  Academy({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.teams,
    required this.staff,
    this.battles = const [],
  });
}

class Team {
  String id;
  String name;
  List<Player> players;
  String ageGroup;
  int colorValue;
  String? logoPath;
  String? coachStaffId;
  String? assistantCoachStaffId;

  Team({
    required this.id,
    required this.name,
    required this.players,
    this.ageGroup = 'Open',
    this.colorValue = 0xFFF59E0B,
    this.logoPath,
    this.coachStaffId,
    this.assistantCoachStaffId,
  });
}

class Player {
  String id;
  String name;
  String email;
  String? tempPassword;
  String position;
  int age;
  int matchesPlayed;
  int wins;
  int points;
  String height;
  String weight;
  String wingspan;
  String jerseyNumber;
  String scoutingNotes;
  String classYear;
  bool isEliteProspect;
  double ppg;
  double apg;
  double rpg;
  String? profileImageUrl;

  Player({
    required this.id,
    required this.name,
    required this.email,
    this.tempPassword,
    required this.position,
    required this.age,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.points = 0,
    this.height = 'N/A',
    this.weight = 'N/A',
    this.wingspan = 'N/A',
    this.jerseyNumber = 'N/A',
    this.scoutingNotes = '',
    this.classYear = 'N/A',
    this.isEliteProspect = false,
    this.ppg = 0.0,
    this.apg = 0.0,
    this.rpg = 0.0,
    this.profileImageUrl,
  });
}

class Staff {
  String id;
  String name;
  String email;
  String password;
  String role; // coach, assistant_coach, custom
  String? customRoleName;
  String? profilePic;
  List<String> assignedTeamIds;
  Permissions permissions;

  Staff({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.customRoleName,
    this.profilePic,
    this.assignedTeamIds = const [],
    required this.permissions,
  });
}

class Permissions {
  bool createPlayer;
  bool readPlayer;
  bool updatePlayer;
  bool deletePlayer;
  bool createTeam;
  bool manageStaff;
  bool createBattle;
  bool manageBattle;
  bool createStrategy;
  bool manageStrategy;

  Permissions({
    this.createPlayer = false,
    this.readPlayer = true,
    this.updatePlayer = false,
    this.deletePlayer = false,
    this.createTeam = false,
    this.manageStaff = false,
    this.createBattle = false,
    this.manageBattle = false,
    this.createStrategy = false,
    this.manageStrategy = false,
  });

  // Factory constructor for role-based permissions
  factory Permissions.forRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'head_coach':
        return Permissions(
          createPlayer: true,
          readPlayer: true,
          updatePlayer: true,
          deletePlayer: true,
          createTeam: true,
          manageStaff: true,
          createBattle: true,
          manageBattle: true,
          createStrategy: true,
          manageStrategy: true,
        );
      case 'coach':
        return Permissions(
          createPlayer: true,
          readPlayer: true,
          updatePlayer: true,
          deletePlayer: false,
          createTeam: false,
          manageStaff: false,
          createBattle: true,
          manageBattle: true,
          createStrategy: true,
          manageStrategy: true,
        );
      case 'assistant_coach':
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
      case 'player':
        return Permissions(
          createPlayer: false,
          readPlayer: false,
          updatePlayer: false,
          deletePlayer: false,
          createTeam: false,
          manageStaff: false,
          createBattle: false,
          manageBattle: false,
          createStrategy: false,
          manageStrategy: false,
        );
      default:
        return Permissions(); // Default restrictive permissions
    }
  }

  // Check if user has specific permission
  bool hasPermission(String permission) {
    switch (permission) {
      case 'createPlayer': return createPlayer;
      case 'readPlayer': return readPlayer;
      case 'updatePlayer': return updatePlayer;
      case 'deletePlayer': return deletePlayer;
      case 'createTeam': return createTeam;
      case 'manageStaff': return manageStaff;
      case 'createBattle': return createBattle;
      case 'manageBattle': return manageBattle;
      case 'createStrategy': return createStrategy;
      case 'manageStrategy': return manageStrategy;
      default: return false;
    }
  }

  // Convert to Map for API calls
  Map<String, dynamic> toMap() {
    return {
      'createPlayer': createPlayer,
      'readPlayer': readPlayer,
      'updatePlayer': updatePlayer,
      'deletePlayer': deletePlayer,
      'createTeam': createTeam,
      'manageStaff': manageStaff,
      'createBattle': createBattle,
      'manageBattle': manageBattle,
      'createStrategy': createStrategy,
      'manageStrategy': manageStrategy,
    };
  }

  // Create from Map for API responses
  factory Permissions.fromMap(Map<String, dynamic> map) {
    bool flag(String key, {bool fallback = false}) {
      final v = map[key];
      if (v == null) return fallback;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 'yes';
      }
      return fallback;
    }

    return Permissions(
      createPlayer: flag('createPlayer'),
      readPlayer: flag('readPlayer', fallback: true),
      updatePlayer: flag('updatePlayer'),
      deletePlayer: flag('deletePlayer'),
      createTeam: flag('createTeam'),
      manageStaff: flag('manageStaff'),
      createBattle: flag('createBattle'),
      manageBattle: flag('manageBattle'),
      createStrategy: flag('createStrategy'),
      manageStrategy: flag('manageStrategy'),
    );
  }

  /// API / dialog payloads where [raw] may be a generic [Map].
  factory Permissions.fromDynamic(dynamic raw) {
    if (raw == null) return Permissions();
    if (raw is Map) {
      return Permissions.fromMap(
        Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v))),
      );
    }
    return Permissions();
  }
}

class Battle {
  String id;
  String location;
  DateTime dateTime;
  String status; // pending, ongoing, finished, cancelled
  String? result; // e.g., "15-12"
  String hostId;
  List<String> participantIds;

  Battle({
    required this.id,
    required this.location,
    required this.dateTime,
    required this.status,
    this.result,
    required this.hostId,
    required this.participantIds,
  });
}
