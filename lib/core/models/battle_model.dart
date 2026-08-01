import 'tactical/tactical_schema.dart';

class BattleModel {
  final String id;
  final String location;
  final DateTime dateTime;
  final String status; // pending, ongoing, finished, cancelled
  final String? result;
  final String hostId;
  final String hostName;
  final List<String> participantIds;
  final List<BattleParticipant> participants;
  final String? winnerId;
  final int maxParticipants;
  final String battleType; // 1v1, team, tournament
  final Map<String, dynamic>? metadata;
  final String? description;
  final List<String> tags;
  final int viewCount;
  final DateTime createdAt;
  final bool isJoined;
  final bool canJoin;
  final int participantCount;

  BattleModel({
    required this.id,
    required this.location,
    required this.dateTime,
    required this.status,
    this.result,
    required this.hostId,
    required this.hostName,
    this.participantIds = const [],
    this.participants = const [],
    this.winnerId,
    this.maxParticipants = 2,
    this.battleType = '1v1',
    this.metadata,
    this.description,
    this.tags = const [],
    this.viewCount = 0,
    required this.createdAt,
    this.isJoined = false,
    this.canJoin = true,
    this.participantCount = 0,
  });

  factory BattleModel.fromJson(Map<String, dynamic> json) {
    final participantsList = (json['participants'] as List?)
        ?.map((p) => BattleParticipant.fromJson(Map<String, dynamic>.from(p)))
        .toList() ?? [];

    return BattleModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      dateTime: DateTime.tryParse(json['dateTime']?.toString() ?? '') ?? DateTime.now(),
      status: (json['status'] ?? 'pending').toString(),
      result: json['result']?.toString(),
      hostId: (json['hostId'] ?? json['host']?['_id'] ?? '').toString(),
      hostName: (json['hostName'] ?? json['host']?['username'] ?? 'Host').toString(),
      participantIds: (json['participantIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      participants: participantsList,
      winnerId: json['winnerId']?.toString(),
      maxParticipants: (json['maxParticipants'] ?? 2) as int,
      battleType: (json['battleType'] ?? '1v1').toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      description: json['description']?.toString(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      viewCount: (json['viewCount'] ?? 0) as int,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isJoined: json['isJoined'] == true,
      canJoin: json['canJoin'] == true,
      participantCount: json['participantCount'] is int
          ? json['participantCount']
          : participantsList.length,
    );
  }

  bool get isFull => participants.length >= maxParticipants;
  bool get isOngoing => status == 'ongoing';
  bool get isFinished => status == 'finished';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';

  /// Paused is signaled via [metadata] until the API adds a first-class field.
  bool get isPausedSession => metadata?['sessionPhase']?.toString() == 'paused';

  bool get isPastScheduled => isPending && dateTime.isBefore(DateTime.now());

  BattleSessionPhase get sessionPhase {
    if (isPastScheduled) return BattleSessionPhase.finished;
    return battlePhaseFromModel(status: status, metadata: metadata);
  }

  String get statusDisplayLabel {
    if (isPastScheduled) return 'FINISHED';
    switch (sessionPhase) {
      case BattleSessionPhase.scheduled:
        return 'SCHEDULED';
      case BattleSessionPhase.live:
        return 'LIVE';
      case BattleSessionPhase.paused:
        return 'PAUSED';
      case BattleSessionPhase.finished:
        return isCancelled ? 'CANCELLED' : 'FINISHED';
    }
  }

  int get availableSpots => maxParticipants - participants.length;

  /// User-facing title: session name when set, otherwise location.
  String get displayTitle {
    final fromMeta = metadata?['sessionTitle']?.toString().trim();
    if (fromMeta != null && fromMeta.isNotEmpty) return fromMeta;
    final loc = location.trim();
    if (loc.isNotEmpty) return loc;
    return 'Game';
  }

  static String titleFromMap(Map<String, dynamic> json) {
    final meta = json['metadata'];
    if (meta is Map) {
      final t = meta['sessionTitle']?.toString().trim();
      if (t != null && t.isNotEmpty) return t;
    }
    final loc = json['location']?.toString().trim();
    if (loc != null && loc.isNotEmpty) return loc;
    return 'Game';
  }
}

class BattleParticipant {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? teamId;
  final String? teamName;
  final String? avatarUrl;
  final Map<String, dynamic>? stats;
  final DateTime joinedAt;

  BattleParticipant({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.teamId,
    this.teamName,
    this.avatarUrl,
    this.stats,
    required this.joinedAt,
  });

  factory BattleParticipant.fromJson(Map<String, dynamic> json) {
    final avatar = (json['avatarUrl'] ?? json['profileImageUrl'] ?? json['profilePic'] ?? json['logoUrl'])
        ?.toString()
        .trim();
    return BattleParticipant(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      teamId: json['teamId']?.toString(),
      teamName: json['teamName']?.toString(),
      avatarUrl: (avatar != null && avatar.isNotEmpty) ? avatar : null,
      stats: json['stats'] as Map<String, dynamic>?,
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
