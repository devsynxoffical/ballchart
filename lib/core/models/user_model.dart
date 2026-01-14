class UserModel {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? token;
  final Map<String, dynamic> stats;
  final int rank;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.token,
    this.stats = const {'matchesPlayed': 0, 'wins': 0, 'points': 0},
    this.rank = 0,
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
    };
  }
}
