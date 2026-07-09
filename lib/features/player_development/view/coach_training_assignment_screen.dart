import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ballchart/core/constants/relentless_program.dart';
import 'package:ballchart/core/models/development_models.dart';
import 'package:ballchart/core/repositories/development_repository.dart';
import 'package:ballchart/core/utils/coach_player_resolver.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';
import 'package:ballchart/features/player_development/view/coach_monthly_report_screen.dart';

/// Coach/admin: assign training. Monthly PDF is opened from the app bar (PDF icon).
class CoachTrainingAssignmentScreen extends StatefulWidget {
  const CoachTrainingAssignmentScreen({super.key});

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  State<CoachTrainingAssignmentScreen> createState() => _CoachTrainingAssignmentScreenState();
}

class _CoachTrainingAssignmentScreenState extends State<CoachTrainingAssignmentScreen> {
  final DevelopmentRepository _repo = DevelopmentRepository();
  TrainingCatalogDto? _catalog;
  List<TrainingAssignmentDto> _assignments = [];
  String? _selectedPlayerId;
  String _focus = '';
  String _drill = '';
  String _intent = 'training';
  final _notes = TextEditingController();
  int _points = 10;
  DateTime? _due;
  bool _loading = true;
  bool _saving = false;

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
      if (coachAssignablePlayers(academy).isEmpty && academy.academy.teams.isEmpty) {
        try {
          await academy.loadAdminOverview(force: true);
        } catch (_) {
          // Coach-only accounts may not have admin overview access.
        }
      }
      final cat = await _repo.fetchCatalog();
      if (!mounted) return;
      final focusOpts = RelentlessProgram.mergedFocusOptions(cat.focusAreas);
      setState(() {
        _catalog = cat;
        if (focusOpts.isNotEmpty) _focus = focusOpts.first;
        if (cat.drillTemplates.isNotEmpty) _drill = cat.drillTemplates.first;
        _loading = false;
      });
      if (_selectedPlayerId != null) {
        await _loadAssignments();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _loadAssignments() async {
    final pid = _selectedPlayerId;
    if (pid == null || pid.isEmpty) return;
    final list = await _repo.fetchAssignmentsForPlayer(pid);
    if (mounted) setState(() => _assignments = list);
  }

  List<MapEntry<String, String>> _players(AcademyProvider academy) => coachAssignablePlayers(academy);

  Future<void> _submit() async {
    final pid = _selectedPlayerId;
    if (pid == null || pid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a player')),
      );
      return;
    }
    if (_focus.isEmpty || _drill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose focus area and drill')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.createAssignment(
        playerId: pid,
        focusArea: _focus,
        drillName: _drill,
        sessionIntent: _intent,
        dueAt: _due,
        notes: _notes.text.trim(),
        pointsValue: _points,
      );
      _notes.clear();
      await _loadAssignments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training assigned')),
        );
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

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachTrainingAssignmentScreen.bgColor,
      appBar: AppBar(
        backgroundColor: CoachTrainingAssignmentScreen.bgColor,
        title: const Text(
          'ASSIGN TRAINING',
          style: TextStyle(
            color: CoachTrainingAssignmentScreen.primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Monthly PDF report',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const CoachMonthlyReportScreen(),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, color: CoachTrainingAssignmentScreen.primaryColor),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CoachTrainingAssignmentScreen.primaryColor))
          : Consumer<AcademyProvider>(
              builder: (context, academy, _) {
                final players = _players(academy);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CoachTrainingAssignmentScreen.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CoachTrainingAssignmentScreen.primaryColor.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            RelentlessProgram.subtitle.toUpperCase(),
                            style: const TextStyle(
                              color: CoachTrainingAssignmentScreen.primaryColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            RelentlessProgram.trainingIntro,
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (players.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: CoachTrainingAssignmentScreen.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'No players found. Add players to a team first.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      value: _selectedPlayerId != null &&
                              players.any((e) => e.key == _selectedPlayerId)
                          ? _selectedPlayerId
                          : null,
                      dropdownColor: CoachTrainingAssignmentScreen.surfaceHigh,
                      decoration: _inputDecoration('Player'),
                      items: players
                          .map(
                            (e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: Colors.white))),
                          )
                          .toList(),
                      onChanged: (v) async {
                        setState(() => _selectedPlayerId = v);
                        await _loadAssignments();
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_catalog != null) ...[
                      DropdownButtonFormField<String>(
                        value: () {
                          final opts = RelentlessProgram.mergedFocusOptions(_catalog!.focusAreas);
                          if (opts.isEmpty) return null;
                          return opts.contains(_focus) ? _focus : opts.first;
                        }(),
                        dropdownColor: CoachTrainingAssignmentScreen.surfaceHigh,
                        decoration: _inputDecoration('Development area'),
                        items: RelentlessProgram.mergedFocusOptions(_catalog!.focusAreas)
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (v) => setState(() => _focus = v ?? ''),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _catalog!.drillTemplates.contains(_drill) ? _drill : _catalog!.drillTemplates.first,
                        dropdownColor: CoachTrainingAssignmentScreen.surfaceHigh,
                        decoration: _inputDecoration('Drill / practice'),
                        items: _catalog!.drillTemplates
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (v) => setState(() => _drill = v ?? ''),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _intent,
                      dropdownColor: CoachTrainingAssignmentScreen.surfaceHigh,
                      decoration: _inputDecoration('Session intent'),
                      items: const [
                        DropdownMenuItem(value: 'training', child: Text('Training', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'game_prep', child: Text('Game prep', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'other', child: Text('Other', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setState(() => _intent = v ?? 'training'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Due date (optional)', style: TextStyle(color: Colors.white70)),
                      subtitle: Text(
                        _due == null ? 'Not set' : _due!.toLocal().toString().split(' ').take(2).join(' '),
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today, color: CoachTrainingAssignmentScreen.primaryColor),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _due ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) setState(() => _due = d);
                        },
                      ),
                    ),
                    TextField(
                      controller: _notes,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: _inputDecoration('Coach notes'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Points on completion', style: TextStyle(color: Colors.white70)),
                        Expanded(
                          child: Slider(
                            value: _points.toDouble(),
                            min: 5,
                            max: 50,
                            divisions: 9,
                            label: '$_points',
                            activeColor: CoachTrainingAssignmentScreen.primaryColor,
                            onChanged: (v) => setState(() => _points = v.round()),
                          ),
                        ),
                        Text('$_points', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: CoachTrainingAssignmentScreen.primaryColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Assign training'),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'BY DEVELOPMENT AREA',
                      style: TextStyle(
                        color: CoachTrainingAssignmentScreen.outlineColor,
                        letterSpacing: 2,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_assignments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No assignments yet.', style: TextStyle(color: Colors.white38)),
                      )
                    else
                      ...() {
                        final map = <String, List<TrainingAssignmentDto>>{};
                        for (final a in _assignments.take(40)) {
                          map.putIfAbsent(a.focusArea, () => []).add(a);
                        }
                        final keys = map.keys.toList()..sort(RelentlessProgram.compareAreaKeys);
                        final widgets = <Widget>[];
                        for (final k in keys) {
                          widgets.add(
                            Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      k.toUpperCase(),
                                      style: TextStyle(
                                        color: RelentlessProgram.isStandardArea(k)
                                            ? CoachTrainingAssignmentScreen.primaryColor
                                            : CoachTrainingAssignmentScreen.outlineColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  if (RelentlessProgram.isStandardArea(k))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: CoachTrainingAssignmentScreen.primaryColor.withValues(alpha: 0.5)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'PDF AREA',
                                        style: TextStyle(color: CoachTrainingAssignmentScreen.primaryColor, fontSize: 8, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                          for (final a in map[k]!) {
                            widgets.add(
                              ListTile(
                                dense: true,
                                title: Text(a.drillName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                subtitle: Text(a.status, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                              ),
                            );
                          }
                        }
                        return widgets;
                      }(),
                  ],
                );
              },
            ),
    );
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
}
