import 'dart:typed_data';

import 'package:ballchart/core/models/development_models.dart';
import 'package:ballchart/core/services/api_service.dart';

class DevelopmentRepository {
  final ApiService _api = ApiService();

  Future<TrainingCatalogDto> fetchCatalog() async {
    final res = await _api.get('/player-development/catalog');
    if (res is! Map) throw Exception('Invalid catalog');
    return TrainingCatalogDto.fromJson(Map<String, dynamic>.from(res));
  }

  Future<List<TrainingAssignmentDto>> fetchMyAssignments() async {
    final res = await _api.get('/player-development/my-assignments');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => TrainingAssignmentDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<int> fetchMyPoints() async {
    final res = await _api.get('/player-development/points/me');
    if (res is! Map) return 0;
    final v = res['totalPoints'];
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  Future<TrainingAssignmentDto> completeAssignment(String assignmentId, {String playerNotes = ''}) async {
    final res = await _api.patch(
      '/player-development/assignments/$assignmentId/complete',
      {'playerNotes': playerNotes},
    );
    if (res is! Map) throw Exception('Invalid response');
    return TrainingAssignmentDto.fromJson(Map<String, dynamic>.from(res));
  }

  /// PDF for one completed session (player owner or staff).
  Future<Uint8List> fetchAssignmentCompletionPdf(String assignmentId) {
    return _api.getBytes('/player-development/reports/assignment/$assignmentId/pdf');
  }

  Future<List<TrainingAssignmentDto>> fetchAssignmentsForPlayer(String playerId) async {
    final q = Uri(queryParameters: {'playerId': playerId}).query;
    final res = await _api.get('/player-development/assignments?$q');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => TrainingAssignmentDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createAssignment({
    required String playerId,
    required String focusArea,
    required String drillName,
    String sessionIntent = 'training',
    DateTime? dueAt,
    String notes = '',
    int pointsValue = 10,
  }) async {
    await _api.post('/player-development/assignments', {
      'playerId': playerId,
      'focusArea': focusArea,
      'drillName': drillName,
      'sessionIntent': sessionIntent,
      if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
      'notes': notes,
      'pointsValue': pointsValue,
    });
  }

  Future<Uint8List> fetchMonthlyReportPdf({
    required String playerId,
    required int year,
    required int month,
  }) {
    return _api.getBytes('/player-development/reports/$playerId/$year/$month/pdf');
  }

  Future<PeriodReportDto> fetchPeriodReport({
    required String playerId,
    required int year,
    required int month,
  }) async {
    final q = Uri(queryParameters: {
      'year': '$year',
      'month': '$month',
    }).query;
    final res = await _api.get('/player-development/period-report/$playerId?$q');
    if (res is! Map) throw Exception('Invalid period report');
    return PeriodReportDto.fromJson(Map<String, dynamic>.from(res));
  }

  Future<PeriodReportDto> savePeriodReport({
    required String playerId,
    required int year,
    required int month,
    required String ageCategory,
    required String evaluationPeriod,
    required List<Map<String, dynamic>> areas,
    required String summary,
    required List<String> goals,
    required String nextEvaluationDate,
  }) async {
    final res = await _api.put('/player-development/period-report/$playerId', {
      'year': year,
      'month': month,
      'ageCategory': ageCategory,
      'evaluationPeriod': evaluationPeriod,
      'areas': areas,
      'summary': summary,
      'goals': goals,
      'nextEvaluationDate': nextEvaluationDate,
    });
    if (res is! Map) throw Exception('Invalid save response');
    return PeriodReportDto.fromJson(Map<String, dynamic>.from(res));
  }

  Future<PeriodReportDto> patchPlayerPeriodGoals({
    required String playerId,
    required int year,
    required int month,
    required List<String> playerGoals,
  }) async {
    final res = await _api.patch('/player-development/period-report/$playerId/player-goals', {
      'year': year,
      'month': month,
      'playerGoals': playerGoals,
    });
    if (res is! Map) throw Exception('Invalid response');
    return PeriodReportDto.fromJson(Map<String, dynamic>.from(res));
  }

  /// Staff: update catalog including strategy KPIs (0–100 or null to clear).
  Future<TrainingCatalogDto> updateCatalog({
    List<String>? focusAreas,
    List<String>? drillTemplates,
    int? formationEngagementPct,
    int? drillCompletionPct,
    bool clearFormationEngagementPct = false,
    bool clearDrillCompletionPct = false,
  }) async {
    final body = <String, dynamic>{};
    if (focusAreas != null) body['focusAreas'] = focusAreas;
    if (drillTemplates != null) body['drillTemplates'] = drillTemplates;
    if (clearFormationEngagementPct) {
      body['formationEngagementPct'] = null;
    } else if (formationEngagementPct != null) {
      body['formationEngagementPct'] = formationEngagementPct.clamp(0, 100);
    }
    if (clearDrillCompletionPct) {
      body['drillCompletionPct'] = null;
    } else if (drillCompletionPct != null) {
      body['drillCompletionPct'] = drillCompletionPct.clamp(0, 100);
    }
    final res = await _api.patch('/player-development/catalog', body);
    if (res is! Map) throw Exception('Invalid catalog response');
    return TrainingCatalogDto.fromJson(Map<String, dynamic>.from(res));
  }
}
