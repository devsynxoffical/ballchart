import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ballchart/core/constants/relentless_program.dart';
import 'package:ballchart/core/models/development_models.dart';
import 'package:ballchart/core/repositories/development_repository.dart';
import 'package:ballchart/features/player_development/player_development_theme.dart';
import 'package:ballchart/features/player_development/view/training_completion_report_screen.dart';
import 'package:ballchart/features/profile/viewmodel/profile_viewmodel.dart';

/// Player: assigned training tasks, points, complete actions.
class MyDevelopmentScreen extends StatefulWidget {
  const MyDevelopmentScreen({super.key});

  @override
  State<MyDevelopmentScreen> createState() => _MyDevelopmentScreenState();
}

class _MyDevelopmentScreenState extends State<MyDevelopmentScreen> {
  final DevelopmentRepository _repo = DevelopmentRepository();
  final TextEditingController _personalGoals = TextEditingController();
  List<TrainingAssignmentDto> _items = [];
  int _points = 0;
  bool _loading = true;
  String? _error;
  /// Stays on screen until dismissed (not a short snackbar).
  TrainingAssignmentDto? _completionHighlight;
  int _reportYear = DateTime.now().year;
  int _reportMonth = DateTime.now().month;
  bool _goalsBusy = false;
  bool _pdfBusy = false;
  PeriodReportDto? _periodReport;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPersonalGoals());
  }

  @override
  void dispose() {
    _personalGoals.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalGoals() async {
    final uid = context.read<ProfileViewmodel>().user?.id;
    if (uid == null || uid.isEmpty) return;
    try {
      final r = await _repo.fetchPeriodReport(playerId: uid, year: _reportYear, month: _reportMonth);
      if (mounted) {
        _personalGoals.text = r.playerGoals.join('\n');
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _savePersonalGoals() async {
    final uid = context.read<ProfileViewmodel>().user?.id;
    if (uid == null || uid.isEmpty) return;
    final list = _personalGoals.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() => _goalsBusy = true);
    try {
      await _repo.patchPlayerPeriodGoals(
        playerId: uid,
        year: _reportYear,
        month: _reportMonth,
        playerGoals: list,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your goals were saved for this month')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _goalsBusy = false);
    }
  }

  Future<void> _sharePeriodPdf() async {
    final uid = context.read<ProfileViewmodel>().user?.id;
    if (uid == null || uid.isEmpty) return;
    setState(() => _pdfBusy = true);
    try {
      final bytes = await _repo.fetchMonthlyReportPdf(
        playerId: uid,
        year: _reportYear,
        month: _reportMonth,
      );
      final dir = await getTemporaryDirectory();
      final name = 'my-development-$uid-$_reportYear-${_reportMonth.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Player development report');
    } catch (e) {
      if (mounted) {
        final raw = e.toString().replaceAll('Exception: ', '');
        final friendly = raw.contains('404') || raw.contains('not found')
            ? 'No report for this month yet. Complete training sessions and ask your coach to publish your period report.'
            : raw;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchMyAssignments();
      final p = await _repo.fetchMyPoints();
      PeriodReportDto? report;
      final uid = context.read<ProfileViewmodel>().user?.id;
      if (uid != null && uid.isNotEmpty) {
        try {
          report = await _repo.fetchPeriodReport(playerId: uid, year: _reportYear, month: _reportMonth);
        } catch (_) {
          report = null;
        }
      }
      if (mounted) {
        setState(() {
          _items = list;
          _points = p;
          _periodReport = report;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  void _openCompletionReport(TrainingAssignmentDto a) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TrainingCompletionReportScreen(assignment: a),
      ),
    );
  }

  List<Widget> _groupedAssignmentWidgets() {
    final map = <String, List<TrainingAssignmentDto>>{};
    for (final a in _items) {
      map.putIfAbsent(a.focusArea, () => []).add(a);
    }
    final keys = map.keys.toList()..sort(RelentlessProgram.compareAreaKeys);
    final out = <Widget>[];
    for (final k in keys) {
      out.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  k.toUpperCase(),
                  style: TextStyle(
                    color: RelentlessProgram.isStandardArea(k) ? PlayerDevelopmentTheme.primaryColor : PlayerDevelopmentTheme.outlineColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (RelentlessProgram.isStandardArea(k))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: PlayerDevelopmentTheme.primaryColor.withValues(alpha: 0.45)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'REPORT AREA',
                    style: TextStyle(color: PlayerDevelopmentTheme.primaryColor, fontSize: 8, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ),
      );
      for (final a in map[k]!) {
        out.add(_card(a));
      }
    }
    return out;
  }

  Future<void> _complete(TrainingAssignmentDto a) async {
    try {
      final updated = await _repo.completeAssignment(a.id);
      if (mounted) {
        setState(() => _completionHighlight = updated);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlayerDevelopmentTheme.bgColor,
      appBar: AppBar(
        backgroundColor: PlayerDevelopmentTheme.bgColor,
        elevation: 0,
        title: const Text(
          'MY TRAINING',
          style: TextStyle(
            color: PlayerDevelopmentTheme.primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, color: PlayerDevelopmentTheme.primaryColor),
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
              : RefreshIndicator(
                  color: PlayerDevelopmentTheme.primaryColor,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: PlayerDevelopmentTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: PlayerDevelopmentTheme.primaryColor, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Development points',
                                    style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.9), fontSize: 12),
                                  ),
                                  Text(
                                    '$_points',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: PlayerDevelopmentTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: PlayerDevelopmentTheme.primaryColor.withValues(alpha: 0.28)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              RelentlessProgram.subtitle.toUpperCase(),
                              style: const TextStyle(
                                color: PlayerDevelopmentTheme.primaryColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              RelentlessProgram.trainingIntro,
                              style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.95), fontSize: 12, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PlayerDevelopmentTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PERFORMANCE REPORT · YOUR GOALS',
                              style: TextStyle(
                                color: PlayerDevelopmentTheme.primaryColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add personal goals for the selected month (shown in your PDF with coach goals).',
                              style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.9), fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: _reportMonth,
                                    dropdownColor: PlayerDevelopmentTheme.surfaceHigh,
                                    decoration: InputDecoration(
                                      labelText: 'Month',
                                      labelStyle: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.9)),
                                      filled: true,
                                      fillColor: PlayerDevelopmentTheme.bgColor,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    items: List.generate(
                                      12,
                                      (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}', style: const TextStyle(color: Colors.white))),
                                    ),
                                    onChanged: (v) async {
                                      if (v == null) return;
                                      setState(() => _reportMonth = v);
                                      await _loadPersonalGoals();
                                      await _load();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: _reportYear,
                                    dropdownColor: PlayerDevelopmentTheme.surfaceHigh,
                                    decoration: InputDecoration(
                                      labelText: 'Year',
                                      labelStyle: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.9)),
                                      filled: true,
                                      fillColor: PlayerDevelopmentTheme.bgColor,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    items: [
                                      for (var y = DateTime.now().year - 1; y <= DateTime.now().year + 1; y++)
                                        DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(color: Colors.white))),
                                    ],
                                    onChanged: (v) async {
                                      if (v == null) return;
                                      setState(() => _reportYear = v);
                                      await _loadPersonalGoals();
                                      await _load();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _personalGoals,
                              minLines: 2,
                              maxLines: 5,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'One goal per line…',
                                hintStyle: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.5)),
                                filled: true,
                                fillColor: PlayerDevelopmentTheme.bgColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _goalsBusy ? null : _savePersonalGoals,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: PlayerDevelopmentTheme.primaryColor,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: _goalsBusy
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                          )
                                        : const Text('Save my goals'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _pdfBusy ? null : _sharePeriodPdf,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: PlayerDevelopmentTheme.primaryColor,
                                      side: BorderSide(color: PlayerDevelopmentTheme.primaryColor.withValues(alpha: 0.6)),
                                    ),
                                    child: _pdfBusy
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: PlayerDevelopmentTheme.primaryColor),
                                          )
                                        : const Text('PDF report'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_periodReport != null) ...[
                        const SizedBox(height: 16),
                        _buildCoachReportSection(_periodReport!),
                      ],
                      if (_completionHighlight != null) ...[
                        const SizedBox(height: 16),
                        _buildCompletionHighlightBanner(),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'TRAINING BY DEVELOPMENT AREA',
                        style: TextStyle(
                          color: PlayerDevelopmentTheme.outlineColor,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No training assigned yet. Your coach will assign sessions under the same development areas as your performance report.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.85)),
                          ),
                        )
                      else
                        ..._groupedAssignmentWidgets(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCoachReportSection(PeriodReportDto report) {
    final areas = RelentlessProgram.mergeReportAreas(report.areas);
    final hasContent = report.summary.trim().isNotEmpty ||
        report.goals.isNotEmpty ||
        areas.any((a) => (a.rating ?? 0) > 0 || a.performanceComment.trim().isNotEmpty);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlayerDevelopmentTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFORMANCE REPORT · COACH FEEDBACK',
            style: TextStyle(
              color: PlayerDevelopmentTheme.primaryColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          if (!hasContent)
            Text(
              'Your coach has not published feedback for this month yet.',
              style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.9), fontSize: 12),
            )
          else ...[
            if (report.summary.trim().isNotEmpty) ...[
              Text(report.summary.trim(), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
              const SizedBox(height: 12),
            ],
            ...areas.map((a) {
              final hasArea = (a.rating ?? 0) > 0 ||
                  a.performanceComment.trim().isNotEmpty ||
                  a.strengths.trim().isNotEmpty ||
                  a.focusArea.trim().isNotEmpty;
              if (!hasArea) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    if (a.rating != null)
                      Text('Rating: ${a.rating}/5', style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.95), fontSize: 12)),
                    if (a.performanceComment.trim().isNotEmpty)
                      Text(a.performanceComment.trim(), style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.95), fontSize: 12)),
                  ],
                ),
              );
            }),
            if (report.goals.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Coach goals', style: TextStyle(color: PlayerDevelopmentTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12)),
              ...report.goals.map((g) => Text('• $g', style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.95), fontSize: 12))),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionHighlightBanner() {
    final a = _completionHighlight!;
    return Material(
      color: PlayerDevelopmentTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PlayerDevelopmentTheme.primaryColor.withValues(alpha: 0.55)),
          color: PlayerDevelopmentTheme.primaryColor.withValues(alpha: 0.08),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: PlayerDevelopmentTheme.primaryColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Session completed · +${a.pointsValue} development points',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _completionHighlight = null),
                  icon: const Icon(Icons.close, color: Colors.white54),
                  tooltip: 'Dismiss',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${a.focusArea} · ${a.drillName}',
              style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.95), fontSize: 13),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: PlayerDevelopmentTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _openCompletionReport(a),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: const Text('View completion PDF', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(TrainingAssignmentDto a) {
    final pending = a.status == 'pending';
    return Card(
      color: PlayerDevelopmentTheme.surfaceHigh,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (RelentlessProgram.isStandardArea(a.focusArea))
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: PlayerDevelopmentTheme.primaryColor.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CORE',
                        style: TextStyle(color: PlayerDevelopmentTheme.primaryColor, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PlayerDevelopmentTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    a.sessionIntent.replaceAll('_', ' '),
                    style: const TextStyle(color: PlayerDevelopmentTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Text(
                  pending ? 'Pending' : a.status,
                  style: TextStyle(
                    color: pending ? Colors.orangeAccent : Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              a.focusArea,
              style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.95), fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              a.drillName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (a.notes != null && a.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(a.notes!, style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.95), fontSize: 13)),
            ],
            if (a.dueAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Due: ${a.dueAt!.toLocal().toString().split(' ').take(2).join(' ')}',
                  style: TextStyle(color: PlayerDevelopmentTheme.outlineColor.withValues(alpha: 0.8), fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            Text('+${a.pointsValue} pts on completion', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if (pending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: PlayerDevelopmentTheme.primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _complete(a),
                  child: const Text('Mark complete'),
                ),
              ),
            ] else if (a.status == 'completed') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: PlayerDevelopmentTheme.primaryColor,
                  side: const BorderSide(color: PlayerDevelopmentTheme.primaryColor),
                  minimumSize: const Size(double.infinity, 44),
                ),
                onPressed: () => _openCompletionReport(a),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: const Text('Open completion PDF'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
