class UserModel {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? token;
  final Map<String, dynamic> stats;
  final int rank;
  final bool profileCompleted;
  final String? academyId;
  final String? parentId; // createdBy
  final String? managedBy;
  final Map<String, dynamic>? permissions;

  // Coach specific
  final String? experienceLevel;
  final List<String>? sports;
  final List<String>? achievements;
  final String? additionalInfo;
  final String? teamName;
  final String? academyName;
  final List<String>? assignedTeams;
  final List<String>? assignedTeamIds;
  // Player specific
  final String? position;
  final String? ageRange;
  final List<String>? goals;
  final String? additionalGoals;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.token,
    this.academyId,
    this.parentId,
    this.managedBy,
    this.permissions,
    this.stats = const {'matchesPlayed': 0, 'wins': 0, 'points': 0},
    this.rank = 0,
    this.profileCompleted = false,
    this.experienceLevel,
    this.sports,
    this.achievements,
    this.additionalInfo,
    this.teamName,
    this.academyName,
    this.assignedTeams,
    this.assignedTeamIds,
    this.position,
    this.ageRange,
    this.goals,
    this.additionalGoals,
    this.profileImageUrl,
  });

  static String? _avatarFromJson(Map<String, dynamic> json) {
    final raw = (json['profileImageUrl'] ?? json['profilePic'] ?? json['logoUrl'])?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    // Keep relative paths; UI resolves via ApiService.resolveMediaUrl.
    return raw;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] ?? '').toString();
    final resolvedAcademyName = (json['academyName'] ??
            (json['academy'] is Map ? json['academy']['academyName'] : null) ??
            (json['academy'] is Map ? json['academy']['name'] : null))
        ?.toString();
    final resolvedTeamName = json['teamName']?.toString();
    final rawId = json['_id'] ?? json['id'];
    final id = rawId is Map
        ? (rawId['_id'] ?? rawId['id'] ?? '').toString()
        : (rawId ?? '').toString();

    return UserModel(
      id: id,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: role,
      token: json['token'],
      academyId: json['academy'] is String ? json['academy'] : json['academy']?['_id'], // Handle population
      parentId: json['createdBy'],
      managedBy: json['managedBy'],
      permissions: json['permissions'] is Map ? Map<String, dynamic>.from(json['permissions']) : null,
      stats: json['stats'] ?? {'matchesPlayed': 0, 'wins': 0, 'points': 0},
      rank: json['rank'] ?? 0,
      profileCompleted: json['profileCompleted'] ?? false,
      experienceLevel: json['experienceLevel'],
      sports: json['sports'] != null ? List<String>.from(json['sports']) : null,
      achievements: json['achievements'] != null ? List<String>.from(json['achievements']) : null,
      additionalInfo: json['additionalInfo'],
      teamName: role == 'admin'
          ? (resolvedAcademyName ?? resolvedTeamName)
          : (resolvedTeamName ?? resolvedAcademyName),
      academyName: resolvedAcademyName,
      assignedTeams: json['assignedTeams'] != null ? List<String>.from(json['assignedTeams']) : null,
      assignedTeamIds: json['assignedTeamIds'] != null
          ? List<String>.from(json['assignedTeamIds'])
          : (json['assignedTeams'] != null ? List<String>.from(json['assignedTeams']) : null),
      position: json['position'],
      ageRange: json['ageRange'],
      goals: json['goals'] != null ? List<String>.from(json['goals']) : null,
      additionalGoals: json['additionalGoals'],
      profileImageUrl: _avatarFromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'role': role,
      'token': token,
      'stats': stats,
      'rank': rank,
      'profileCompleted': profileCompleted,
      'experienceLevel': experienceLevel,
      'sports': sports,
      'achievements': achievements,
      'additionalInfo': additionalInfo,
      'teamName': teamName,
      'academyName': teamName,
      'resolvedAcademyName': academyName,
      'assignedTeams': assignedTeams,
      'assignedTeamIds': assignedTeamIds,
      'permissions': permissions,
      'position': position,
      'ageRange': ageRange,
      'goals': goals,
      'additionalGoals': additionalGoals,
      'profileImageUrl': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? token,
    Map<String, dynamic>? stats,
    int? rank,
    bool? profileCompleted,
    String? academyId,
    String? parentId,
    String? managedBy,
    Map<String, dynamic>? permissions,
    bool clearPermissions = false,
    String? experienceLevel,
    List<String>? sports,
    List<String>? achievements,
    String? additionalInfo,
    String? teamName,
    String? academyName,
    List<String>? assignedTeams,
    List<String>? assignedTeamIds,
    String? position,
    String? ageRange,
    List<String>? goals,
    String? additionalGoals,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      stats: stats ?? this.stats,
      rank: rank ?? this.rank,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      academyId: academyId ?? this.academyId,
      parentId: parentId ?? this.parentId,
      managedBy: managedBy ?? this.managedBy,
      permissions: clearPermissions ? null : (permissions ?? this.permissions),
      experienceLevel: experienceLevel ?? this.experienceLevel,
      sports: sports ?? this.sports,
      achievements: achievements ?? this.achievements,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      teamName: teamName ?? this.teamName,
      academyName: academyName ?? this.academyName,
      assignedTeams: assignedTeams ?? this.assignedTeams,
      assignedTeamIds: assignedTeamIds ?? this.assignedTeamIds,
      position: position ?? this.position,
      ageRange: ageRange ?? this.ageRange,
      goals: goals ?? this.goals,
      additionalGoals: additionalGoals ?? this.additionalGoals,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
