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
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: json['type'] ?? '',
      isRead: json['isRead'] ?? false,
      relatedUserId: json['relatedUserId'],
      relatedTeamId: json['relatedTeamId'],
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
      NotificationModel(
        id: '2',
        title: 'Coach Added',
        message: 'Sarah Johnson has been added as Assistant Coach',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: 'coach_added',
        relatedUserId: 'coach_1',
      ),
      NotificationModel(
        id: '3',
        title: 'Team Created',
        message: 'U-16 Competitive team has been created',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'team_created',
        relatedTeamId: 'team_2',
      ),
      NotificationModel(
        id: '4',
        title: 'Battle Scheduled',
        message: 'Practice match scheduled for tomorrow',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: 'battle_scheduled',
      ),
      NotificationModel(
        id: '5',
        title: 'Strategy Added',
        message: 'New offensive strategy added to playbook',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        type: 'strategy_added',
      ),
    ];
  }
}
