import 'user_model.dart';

class BattleModel {
  final String id;
  final UserModel? host;
  final String location;
  final DateTime dateTime;
  final String status;
  final List<UserModel> participants;
  final UserModel? winner;
  final String? result;

  BattleModel({
    required this.id,
    this.host,
    required this.location,
    required this.dateTime,
    required this.status,
    required this.participants,
    this.winner,
    this.result,
  });

  factory BattleModel.fromJson(Map<String, dynamic> json) {
    return BattleModel(
      id: json['_id'],
      host: json['host'] is Map ? UserModel.fromJson(Map<String, dynamic>.from(json['host'])) : null, // Handle populated vs unpopulated
      location: json['location'],
      dateTime: DateTime.parse(json['dateTime']),
      status: json['status'],
      participants: (json['participants'] as List)
          .map((e) => e is Map ? UserModel.fromJson(Map<String, dynamic>.from(e)) : UserModel(id: e.toString(), username: '', email: '', role: '')) // Handle populated vs IDs
          .toList(),
      winner: json['winner'] != null
          ? (json['winner'] is Map ? UserModel.fromJson(Map<String, dynamic>.from(json['winner'])) : null)
          : null,
      result: json['result'],
    );
  }
}
