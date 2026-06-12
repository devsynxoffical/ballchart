class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'player_joined', 'coach_added', 'team_created', etc.
  final bool isRead;
  final String? relatedUserId;
  final String? relatedTeamId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.relatedUserId,
    this.relatedTeamId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final rawTs = json['timestamp'] ?? json['createdAt'];
    DateTime ts = DateTime.now();
    if (rawTs != null) {
      ts = DateTime.tryParse(rawTs.toString()) ?? ts;
    }
    return NotificationModel(
      id: rawId?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: ts,
      type: json['type']?.toString() ?? 'system',
      isRead: json['isRead'] == true,
      relatedUserId: json['relatedUserId']?.toString(),
      relatedTeamId: json['relatedTeamId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isRead': isRead,
      'relatedUserId': relatedUserId,
      'relatedTeamId': relatedTeamId,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    String? type,
    bool? isRead,
    String? relatedUserId,
    String? relatedTeamId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedTeamId: relatedTeamId ?? this.relatedTeamId,
    );
  }
}

/// Legacy mock list for tests / offline demos only — app UI loads from API.
class NotificationService {
  static List<NotificationModel> getMockNotifications() {
    return [
      NotificationModel(
        id: '1',
        title: 'New Player Joined',
        message: 'John Smith has joined the U-14 team',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'player_joined',
        relatedUserId: 'player_1',
        relatedTeamId: 'team_1',
      ),
    ];
  }
}
