import 'package:flutter/material.dart';
import 'package:ballchart/core/models/development_models.dart';
import 'package:ballchart/core/repositories/development_repository.dart';
import 'package:ballchart/features/player_development/player_development_theme.dart';

/// Staff: edit Relentless-style period report (ratings, insights, summary, goals).
class CoachPeriodReportEditorScreen extends StatefulWidget {
  const CoachPeriodReportEditorScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.year,
    required this.month,
  });

  final String playerId;
  final String playerName;
  final int year;
  final int month;

  @override
  State<CoachPeriodReportEditorScreen> createState() => _CoachPeriodReportEditorScreenState();
}

class _CoachPeriodReportEditorScreenState extends State<CoachPeriodReportEditorScreen> {
  final DevelopmentRepository _repo = DevelopmentRepository();
  final TextEditingController _ageCategory = TextEditingController();
  final TextEditingController _evaluationPeriod = TextEditingController();
  final TextEditingController _summary = TextEditingController();
  final TextEditingController _goals = TextEditingController();
  final TextEditingController _nextEval = TextEditingController();

  List<PeriodReportAreaDto> _areas = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ageCategory.dispose();
    _evaluationPeriod.dispose();
    _summary.dispose();
    _goals.dispose();
    _nextEval.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _repo.fetchPeriodReport(
        playerId: widget.playerId,
        year: widget.year,
        month: widget.month,
      );
      if (!mounted) return;
      _ageCategory.text = r.ageCategory;
      _evaluationPeriod.text = r.evaluationPeriod;
      _summary.text = r.summary;
      _goals.text = r.goals.join('\n');
      _nextEval.text = r.nextEvaluationDate;
      setState(() {
        _areas = List<PeriodReportAreaDto>.from(r.areas.map((e) => PeriodReportAreaDto(
              key: e.key,
              label: e.label,
              rating: e.rating,
              performanceComment: e.performanceComment,
              strengths: e.strengths,
              focusArea: e.focusArea,
            )));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final goals = _goals.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await _repo.savePeriodReport(
        playerId: widget.playerId,
        year: widget.year,
        month: widget.month,
        ageCategory: _ageCategory.text.trim(),
        evaluationPeriod: _evaluationPeriod.text.trim(),
        areas: _areas.map((e) => e.toJson()).toList(),
        summary: _summary.text.trim(),
        goals: goals,
        nextEvaluationDate: _nextEval.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report saved')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _updateArea(int i, PeriodReportAreaDto next) {
    setState(() => _areas[i] = next);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        '${widget.playerName} · ${widget.year}-${widget.month.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: PlayerDevelopmentTheme.bgColor,
      appBar: AppBar(
        backgroundColor: PlayerDevelopmentTheme.bgColor,
        title: Text(
          'PERFORMANCE REPORT',
          style: TextStyle(
            color: PlayerDevelopmentTheme.primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _save,
            child: Text(
              'SAVE',
              style: TextStyle(
                color: PlayerDevelopmentTheme.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PlayerDevelopmentTheme.primaryColor))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Performance Development Program — align ratings (1–5), comments, strengths, and focus areas. '
                      'Then generate the PDF from the monthly report screen.',
                      style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.95), fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    _field('Age category (e.g. U18)', _ageCategory),
                    const SizedBox(height: 12),
                    _field('Evaluation period (e.g. Term 1 – 2025)', _evaluationPeriod),
                    const SizedBox(height: 20),
                    ...List.generate(_areas.length, (i) {
                      final a = _areas[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          collapsedBackgroundColor: PlayerDevelopmentTheme.surfaceHigh,
                          backgroundColor: PlayerDevelopmentTheme.surfaceHigh,
                          textColor: Colors.white,
                          iconColor: PlayerDevelopmentTheme.primaryColor,
                          title: Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          children: [
                            Row(
                              children: [
                                const Text('Rating (1–5)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(width: 12),
                                DropdownButton<int?>(
                                  value: a.rating,
                                  dropdownColor: PlayerDevelopmentTheme.surfaceHigh,
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text('—', style: TextStyle(color: Colors.white))),
                                    for (var n = 1; n <= 5; n++)
                                      DropdownMenuItem<int?>(
                                        value: n,
                                        child: Text('$n', style: const TextStyle(color: Colors.white)),
                                      ),
                                  ],
                                  onChanged: (v) => _updateArea(
                                    i,
                                    PeriodReportAreaDto(
                                      key: a.key,
                                      label: a.label,
                                      rating: v,
                                      performanceComment: a.performanceComment,
                                      strengths: a.strengths,
                                      focusArea: a.focusArea,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _areaField(
                              areaKey: a.key,
                              keySuffix: 'perf',
                              label: 'Performance comments',
                              value: a.performanceComment,
                              onChanged: (t) => _updateArea(
                                i,
                                PeriodReportAreaDto(
                                  key: a.key,
                                  label: a.label,
                                  rating: a.rating,
                                  performanceComment: t,
                                  strengths: a.strengths,
                                  focusArea: a.focusArea,
                                ),
                              ),
                            ),
                            _areaField(
                              areaKey: a.key,
                              keySuffix: 'str',
                              label: 'Strengths',
                              value: a.strengths,
                              onChanged: (t) => _updateArea(
                                i,
                                PeriodReportAreaDto(
                                  key: a.key,
                                  label: a.label,
                                  rating: a.rating,
                                  performanceComment: a.performanceComment,
                                  strengths: t,
                                  focusArea: a.focusArea,
                                ),
                              ),
                            ),
                            _areaField(
                              areaKey: a.key,
                              keySuffix: 'foc',
                              label: 'Focus area',
                              value: a.focusArea,
                              onChanged: (t) => _updateArea(
                                i,
                                PeriodReportAreaDto(
                                  key: a.key,
                                  label: a.label,
                                  rating: a.rating,
                                  performanceComment: a.performanceComment,
                                  strengths: a.strengths,
                                  focusArea: t,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Text('Summary', style: TextStyle(color: PlayerDevelopmentTheme.primaryColor, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _summary,
                      minLines: 4,
                      maxLines: 8,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration(hint: 'Overall summary for this period'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Goals for next term (one per line)',
                      style: TextStyle(color: PlayerDevelopmentTheme.primaryColor, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _goals,
                      minLines: 4,
                      maxLines: 10,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration(hint: 'Each line becomes a bullet in the PDF'),
                    ),
                    const SizedBox(height: 16),
                    _field('Next evaluation date', _nextEval),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: PlayerDevelopmentTheme.primaryColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Save report'),
                    ),
                  ],
                ),
    );
  }

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.7)),
      filled: true,
      fillColor: PlayerDevelopmentTheme.surfaceHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration(),
        ),
      ],
    );
  }

  Widget _areaField({
    required String areaKey,
    required String keySuffix,
    required String label,
    required String value,
    required void Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          TextFormField(
            key: ValueKey('${widget.playerId}-${widget.year}-${widget.month}-$areaKey-$keySuffix'),
            initialValue: value,
            minLines: 1,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _decoration(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
