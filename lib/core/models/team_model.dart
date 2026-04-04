class TeamModel {
  final String id;
  final String name;
  final String ageGroup;
  final String? logoUrl;
  final String color; // Hex string or predefined color name
  final String coachId;
  final List<String> members;

  TeamModel({
    required this.id,
    required this.name,
    required this.ageGroup,
    this.logoUrl,
    required this.color,
    required this.coachId,
    this.members = const [],
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      ageGroup: json['ageGroup'] ?? '',
      logoUrl: json['logoUrl'],
      color: json['color'] ?? '0xFF1E88E5', // Default blue
      coachId: json['coachId'] ?? '',
      members: List<String>.from(json['members'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ageGroup': ageGroup,
      'logoUrl': logoUrl,
      'color': color,
      'coachId': coachId,
      'members': members,
    };
  }
}
