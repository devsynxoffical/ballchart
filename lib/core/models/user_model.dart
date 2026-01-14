class UserModel {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? token;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'], // Backend uses _id
      username: json['username'],
      email: json['email'],
      role: json['role'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'role': role,
      'token': token,
    };
  }
}
