import 'user_model.dart';

class BattleModel {
  final String id;
  final UserModel? host;
  final String location;
  final DateTime dateTime;
  final String status;
  final List<UserModel> participants;
  final int participantCount;
  final bool isJoined;
  final bool canJoin;
  final UserModel? winner;
  final String? result;

  BattleModel({
    required this.id,
    this.host,
    required this.location,
    required this.dateTime,
    required this.status,
    required this.participants,
    required this.participantCount,
    required this.isJoined,
    required this.canJoin,
    this.winner,
    this.result,
  });

  factory BattleModel.fromJson(Map<String, dynamic> json) {
    final participantsRaw = (json['participants'] as List?) ?? const [];
    final participants = participantsRaw
        .map((e) => e is Map
            ? UserModel.fromJson(Map<String, dynamic>.from(e))
            : UserModel(id: e.toString(), username: '', email: '', role: ''))
        .toList();

    return BattleModel(
      id: json['_id'] ?? '',
      host: json['host'] is Map ? UserModel.fromJson(Map<String, dynamic>.from(json['host'])) : null,
      location: json['location'] ?? '',
      dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'pending',
      participants: participants,
      participantCount: json['participantCount'] is int
          ? json['participantCount']
          : participants.length,
      isJoined: json['isJoined'] == true,
      canJoin: json['canJoin'] == true,
      winner: json['winner'] != null
          ? (json['winner'] is Map ? UserModel.fromJson(Map<String, dynamic>.from(json['winner'])) : null)
          : null,
      result: json['result'],
    );
  }
}
