import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ballchart/core/constants/relentless_program.dart';
import 'package:ballchart/core/repositories/development_repository.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';
import 'package:ballchart/features/player_development/view/coach_period_report_editor_screen.dart';
import 'package:ballchart/features/player_development/view/coach_training_assignment_screen.dart';

/// Staff-only: pick player + month and generate the monthly development PDF.
class CoachMonthlyReportScreen extends StatefulWidget {
  const CoachMonthlyReportScreen({super.key});

  @override
  State<CoachMonthlyReportScreen> createState() => _CoachMonthlyReportScreenState();
}

class _CoachMonthlyReportScreenState extends State<CoachMonthlyReportScreen> {
  final DevelopmentRepository _repo = DevelopmentRepository();
  String? _selectedPlayerId;
  int _reportYear = DateTime.now().year;
  int _reportMonth = DateTime.now().month;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final academy = context.read<AcademyProvider>();
    try {
      if (academy.coachDashboard == null) {
        await academy.loadCoachDashboard(force: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MapEntry<String, String>> _playersFromDashboard(AcademyProvider academy) {
    final teams = academy.coachDashboard?['teams'] as List<dynamic>? ?? [];
    final seen = <String>{};
    final out = <MapEntry<String, String>>[];
    for (final t in teams) {
      if (t is! Map) continue;
      final players = t['players'] as List<dynamic>? ?? [];
      for (final p in players) {
        if (p is! Map) continue;
        final id = (p['_id'] ?? p['id'] ?? '').toString();
        if (id.isEmpty || seen.contains(id)) continue;
        seen.add(id);
        final name = p['username']?.toString() ?? 'Player';
        out.add(MapEntry(id, name));
      }
    }
    return out;
  }

  Future<void> _downloadPdf() async {
    final pid = _selectedPlayerId;
    if (pid == null || pid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a player first')),
      );
      return;
    }
    try {
      final bytes = await _repo.fetchMonthlyReportPdf(
        playerId: pid,
        year: _reportYear,
        month: _reportMonth,
      );
      final dir = await getTemporaryDirectory();
      final name = 'development-$pid-$_reportYear-${_reportMonth.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Player development report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      labelText: hint,
      labelStyle: TextStyle(color: CoachTrainingAssignmentScreen.outlineColor.withValues(alpha: 0.9)),
      filled: true,
      fillColor: CoachTrainingAssignmentScreen.surfaceHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachTrainingAssignmentScreen.bgColor,
      appBar: AppBar(
        backgroundColor: CoachTrainingAssignmentScreen.bgColor,
        title: const Text(
          'MONTHLY PDF REPORT',
          style: TextStyle(
            color: CoachTrainingAssignmentScreen.primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CoachTrainingAssignmentScreen.primaryColor))
          : Consumer<AcademyProvider>(
              builder: (context, academy, _) {
                final players = _playersFromDashboard(academy);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Summarize all completed sessions in the selected calendar month. The PDF uses the ${RelentlessProgram.subtitle} layout (same six development areas as training assignments).',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedPlayerId != null && players.any((e) => e.key == _selectedPlayerId)
                          ? _selectedPlayerId
                          : null,
                      dropdownColor: CoachTrainingAssignmentScreen.surfaceHigh,
                      decoration: _inputDecoration('Player'),
                      items: players
                          .map(
                            (e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: Colors.white))),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPlayerId = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _reportMonth,
                            dropdownColor: CoachTrainingAssignmentScreen.surfaceHigh,
                            decoration: _inputDecoration('Month'),
                            items: List.generate(
                              12,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                            onChanged: (v) => setState(() => _reportMonth = v ?? 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _reportYear,
                            dropdownColor: CoachTrainingAssignmentScreen.surfaceHigh,
                            decoration: _inputDecoration('Year'),
                            items: [
                              for (var y = DateTime.now().year - 1; y <= DateTime.now().year + 1; y++)
                                DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(color: Colors.white))),
                            ],
                            onChanged: (v) => setState(() => _reportYear = v ?? DateTime.now().year),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CoachTrainingAssignmentScreen.primaryColor,
                        side: BorderSide(color: CoachTrainingAssignmentScreen.primaryColor.withValues(alpha: 0.5)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _selectedPlayerId == null || _selectedPlayerId!.isEmpty
                          ? null
                          : () async {
                              var name = 'Player';
                              for (final e in players) {
                                if (e.key == _selectedPlayerId) {
                                  name = e.value;
                                  break;
                                }
                              }
                              final ok = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => CoachPeriodReportEditorScreen(
                                    playerId: _selectedPlayerId!,
                                    playerName: name,
                                    year: _reportYear,
                                    month: _reportMonth,
                                  ),
                                ),
                              );
                              if (ok == true && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Saved — you can generate the PDF below')),
                                );
                              }
                            },
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Edit performance report (ratings & insights)'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: CoachTrainingAssignmentScreen.primaryColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _downloadPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generate & share PDF'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
