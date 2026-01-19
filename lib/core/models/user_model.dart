class UserModel {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? token;
  final Map<String, dynamic> stats;
  final int rank;
  final bool profileCompleted;
  // Coach specific
  final String? experienceLevel;
  final List<String>? sports;
  final List<String>? achievements;
  final String? additionalInfo;
  // Player specific
  final String? position;
  final String? ageRange;
  final List<String>? goals;
  final String? additionalGoals;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.token,
    this.stats = const {'matchesPlayed': 0, 'wins': 0, 'points': 0},
    this.rank = 0,
    this.profileCompleted = false,
    this.experienceLevel,
    this.sports,
    this.achievements,
    this.additionalInfo,
    this.position,
    this.ageRange,
    this.goals,
    this.additionalGoals,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'], // Backend uses _id
      username: json['username'],
      email: json['email'],
      role: json['role'],
      token: json['token'],
      stats: json['stats'] ?? {'matchesPlayed': 0, 'wins': 0, 'points': 0},
      rank: json['rank'] ?? 0,
      profileCompleted: json['profileCompleted'] ?? false,
      experienceLevel: json['experienceLevel'],
      sports: json['sports'] != null ? List<String>.from(json['sports']) : null,
      achievements: json['achievements'] != null ? List<String>.from(json['achievements']) : null,
      additionalInfo: json['additionalInfo'],
      position: json['position'],
      ageRange: json['ageRange'],
      goals: json['goals'] != null ? List<String>.from(json['goals']) : null,
      additionalGoals: json['additionalGoals'],
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
      'position': position,
      'ageRange': ageRange,
      'goals': goals,
      'additionalGoals': additionalGoals,
    };
  }
}
