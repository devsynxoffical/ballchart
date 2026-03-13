class StrategyModel {
  final String id;
  final String title;
  final String category;
  final String sourceType;
  final String sourceText;
  final String videoUrl;
  final DateTime createdAt;
  final String createdByName;
  final String createdByRole;

  StrategyModel({
    required this.id,
    required this.title,
    required this.category,
    required this.sourceType,
    required this.sourceText,
    required this.videoUrl,
    required this.createdAt,
    required this.createdByName,
    required this.createdByRole,
  });

  factory StrategyModel.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] is Map
        ? Map<String, dynamic>.from(json['createdBy'])
        : <String, dynamic>{};

    return StrategyModel(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      sourceType: (json['sourceType'] ?? 'text').toString(),
      sourceText: (json['sourceText'] ?? '').toString(),
      videoUrl: (json['videoUrl'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      createdByName: (createdBy['username'] ?? 'Coach').toString(),
      createdByRole: (createdBy['role'] ?? '').toString(),
    );
  }
}
