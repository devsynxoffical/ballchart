class TrainingCatalogDto {
  TrainingCatalogDto({
    required this.focusAreas,
    required this.drillTemplates,
    this.formationEngagementPct,
    this.drillCompletionPct,
  });

  final List<String> focusAreas;
  final List<String> drillTemplates;
  /// Academy strategy KPIs (0–100), set by staff via PATCH catalog.
  final int? formationEngagementPct;
  final int? drillCompletionPct;

  factory TrainingCatalogDto.fromJson(Map<String, dynamic> json) {
    int? pct(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.round().clamp(0, 100);
      return int.tryParse('$v')?.clamp(0, 100);
    }

    return TrainingCatalogDto(
      focusAreas: (json['focusAreas'] as List?)?.map((e) => e.toString()).toList() ?? [],
      drillTemplates: (json['drillTemplates'] as List?)?.map((e) => e.toString()).toList() ?? [],
      formationEngagementPct: pct(json['formationEngagementPct']),
      drillCompletionPct: pct(json['drillCompletionPct']),
    );
  }
}

/// One row in the Relentless Player Development Program period report.
class PeriodReportAreaDto {
  PeriodReportAreaDto({
    required this.key,
    required this.label,
    this.rating,
    this.performanceComment = '',
    this.strengths = '',
    this.focusArea = '',
  });

  final String key;
  final String label;
  final int? rating;
  final String performanceComment;
  final String strengths;
  final String focusArea;

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'rating': rating,
        'performanceComment': performanceComment,
        'strengths': strengths,
        'focusArea': focusArea,
      };

  factory PeriodReportAreaDto.fromJson(Map<String, dynamic> json) {
    int? r;
    final raw = json['rating'];
    if (raw is num) {
      final v = raw.round();
      r = (v >= 1 && v <= 5) ? v : null;
    }
    return PeriodReportAreaDto(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      rating: r,
      performanceComment: json['performanceComment']?.toString() ?? '',
      strengths: json['strengths']?.toString() ?? '',
      focusArea: json['focusArea']?.toString() ?? '',
    );
  }
}

/// Full period report (GET/PUT `/player-development/period-report/...`).
class PeriodReportDto {
  PeriodReportDto({
    required this.periodKey,
    required this.playerId,
    required this.ageCategory,
    required this.evaluationPeriod,
    required this.areas,
    required this.summary,
    required this.goals,
    required this.playerGoals,
    required this.nextEvaluationDate,
  });

  final String periodKey;
  final String playerId;
  final String ageCategory;
  final String evaluationPeriod;
  final List<PeriodReportAreaDto> areas;
  final String summary;
  final List<String> goals;
  final List<String> playerGoals;
  final String nextEvaluationDate;

  factory PeriodReportDto.fromJson(Map<String, dynamic> json) {
    final rawAreas = json['areas'];
    final areas = rawAreas is List
        ? rawAreas
            .whereType<Map>()
            .map((e) => PeriodReportAreaDto.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <PeriodReportAreaDto>[];
    final goals = json['goals'];
    final pg = json['playerGoals'];
    return PeriodReportDto(
      periodKey: json['periodKey']?.toString() ?? '',
      playerId: json['playerId']?.toString() ?? '',
      ageCategory: json['ageCategory']?.toString() ?? '',
      evaluationPeriod: json['evaluationPeriod']?.toString() ?? '',
      areas: areas,
      summary: json['summary']?.toString() ?? '',
      goals: goals is List ? goals.map((e) => e.toString()).toList() : [],
      playerGoals: pg is List ? pg.map((e) => e.toString()).toList() : [],
      nextEvaluationDate: json['nextEvaluationDate']?.toString() ?? '',
    );
  }
}

class TrainingAssignmentDto {
  TrainingAssignmentDto({
    required this.id,
    required this.playerId,
    required this.focusArea,
    required this.drillName,
    required this.sessionIntent,
    required this.status,
    required this.pointsValue,
    this.dueAt,
    this.notes,
    this.completedAt,
    this.playerNotes,
  });

  final String id;
  final String playerId;
  final String focusArea;
  final String drillName;
  final String sessionIntent;
  final String status;
  final int pointsValue;
  final DateTime? dueAt;
  final String? notes;
  final DateTime? completedAt;
  final String? playerNotes;

  factory TrainingAssignmentDto.fromJson(Map<String, dynamic> json) {
    return TrainingAssignmentDto(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      playerId: (json['playerId'] ?? '').toString(),
      focusArea: json['focusArea']?.toString() ?? '',
      drillName: json['drillName']?.toString() ?? '',
      sessionIntent: json['sessionIntent']?.toString() ?? 'training',
      status: json['status']?.toString() ?? 'pending',
      pointsValue: (json['pointsValue'] is num) ? (json['pointsValue'] as num).toInt() : int.tryParse('${json['pointsValue']}') ?? 0,
      dueAt: json['dueAt'] != null ? DateTime.tryParse(json['dueAt'].toString()) : null,
      notes: json['notes']?.toString(),
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
      playerNotes: json['playerNotes']?.toString(),
    );
  }
}
