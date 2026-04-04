class Academy {
  String id;
  String name;
  String? logoUrl;
  List<Team> teams;
  List<Staff> staff;

  Academy({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.teams,
    required this.staff,
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
  String position;
  int age;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.age,
  });
}

class Staff {
  String id;
  String name;
  String email;
  String password;
  String role; // coach, assistant_coach, custom
  String? customRoleName;
  List<String> assignedTeamIds;
  Permissions permissions;

  Staff({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.customRoleName,
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

  Permissions({
    this.createPlayer = false,
    this.readPlayer = true,
    this.updatePlayer = false,
    this.deletePlayer = false,
    this.createTeam = false,
    this.manageStaff = false,
  });
}

class DummyUser {
  final String id;
  final String name;
  final String role; // academy_owner, coach, player

  const DummyUser({
    required this.id,
    required this.name,
    required this.role,
  });
}
