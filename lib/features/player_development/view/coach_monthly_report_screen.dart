import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ballchart/core/utils/app_messenger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ballchart/core/constants/relentless_program.dart';
import 'package:ballchart/core/repositories/development_repository.dart';
import 'package:ballchart/core/repositories/messaging_repository.dart';
import 'package:ballchart/core/utils/coach_player_resolver.dart';
import 'package:ballchart/core/utils/share_utils.dart';
import 'package:ballchart/features/inbox/viewmodel/inbox_viewmodel.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';
import 'package:ballchart/features/messaging/view/chat_screen.dart';
import 'package:ballchart/features/player_development/view/coach_period_report_editor_screen.dart';
import 'package:ballchart/features/player_development/view/coach_training_assignment_screen.dart';
import 'package:ballchart/features/profile/viewmodel/profile_viewmodel.dart';

/// Staff-only: pick player + month and generate the monthly development PDF.
class CoachMonthlyReportScreen extends StatefulWidget {
  const CoachMonthlyReportScreen({super.key});

  @override
  State<CoachMonthlyReportScreen> createState() => _CoachMonthlyReportScreenState();
}

class _CoachMonthlyReportScreenState extends State<CoachMonthlyReportScreen> {
  final DevelopmentRepository _repo = DevelopmentRepository();
  final MessagingRepository _messagingRepo = MessagingRepository();
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
      if (coachAssignablePlayers(academy).isEmpty && academy.academy.teams.isEmpty) {
        try {
          await academy.loadAdminOverview(force: true);
        } catch (_) {
          // Coach-only accounts may not have admin overview access.
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MapEntry<String, String>> _players(AcademyProvider academy) => coachAssignablePlayers(academy);

  bool _pdfBusy = false;
  bool _sendBusy = false;
  final GlobalKey _shareButtonKey = GlobalKey();
  final GlobalKey _sendButtonKey = GlobalKey();

  String _monthName(int month) {
    const names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) return '$month';
    return names[month - 1];
  }

  Future<void> _downloadPdf() async {
    final pid = _selectedPlayerId;
    if (pid == null || pid.isEmpty) {
      AppMessenger.showSnackBar(context, 
        const SnackBar(content: Text('Select a player first')),
      );
      return;
    }
    setState(() => _pdfBusy = true);
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
      if (!mounted) return;
      await shareFiles(
        context,
        files: [XFile(file.path)],
        text: 'Player development report',
        anchorKey: _shareButtonKey,
      );
    } catch (e) {
      if (mounted) {
        final raw = e.toString().replaceAll('Exception: ', '');
        final friendly = raw.contains('404') || raw.toLowerCase().contains('not found')
            ? 'Save the performance report first (Edit ratings & insights), then generate the PDF.'
            : raw;
        AppMessenger.showSnackBar(context, 
          SnackBar(content: Text(friendly), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  Future<void> _publishToPlayerChat(List<MapEntry<String, String>> players) async {
    final pid = _selectedPlayerId;
    if (pid == null || pid.isEmpty) {
      AppMessenger.showSnackBar(context, 
        const SnackBar(content: Text('Select a player first')),
      );
      return;
    }

    var playerName = 'Player';
    for (final e in players) {
      if (e.key == pid) {
        playerName = e.value;
        break;
      }
    }

    setState(() => _sendBusy = true);
    try {
      // Ensure the report exists and send it into the in-app chat.
      final bytes = await _repo.fetchMonthlyReportPdf(
        playerId: pid,
        year: _reportYear,
        month: _reportMonth,
      );
      final dir = await getTemporaryDirectory();
      final fileName = 'performance-report-$pid-$_reportYear-${_reportMonth.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      final convo = await _messagingRepo.createOrGetConversation(pid);
      await _messagingRepo.sendPdfMessage(
        convo.id,
        pdfFile: file,
        title: '$playerName — ${_monthName(_reportMonth)} $_reportYear',
      );
      if (!mounted) return;
      context.read<InboxViewModel>().refresh();
      AppMessenger.showSnackBar(context, 
        const SnackBar(
          content: Text('Report sent in BallChart messages'),
          backgroundColor: Colors.green,
        ),
      );
      final me = context.read<ProfileViewmodel>().user;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convo.id,
            otherName: playerName,
            otherId: pid,
            myUserId: me?.id,
            otherAvatarUrl: convo.other?.avatarUrl,
            otherEmail: convo.other?.email,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceAll('Exception: ', '');
      final friendly = raw.contains('404') || raw.toLowerCase().contains('not found')
          ? 'Save the performance report first (Edit ratings & insights), then publish.'
          : raw;
      AppMessenger.showSnackBar(context, 
        SnackBar(content: Text(friendly), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _sendBusy = false);
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
                final players = _players(academy);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Summarize all completed sessions in the selected calendar month. The PDF uses the ${RelentlessProgram.subtitle} layout (${RelentlessProgram.coreAreaCount} core development areas).',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                    ),
                    if (players.isEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: CoachTrainingAssignmentScreen.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'No players found. Add players to a team first, then return here.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
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
                                AppMessenger.showSnackBar(context, 
                                  const SnackBar(
                                    content: Text('Report saved'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Edit performance report (ratings & insights)'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: _sendButtonKey,
                      style: FilledButton.styleFrom(
                        backgroundColor: CoachTrainingAssignmentScreen.primaryColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _sendBusy ? null : () => _publishToPlayerChat(players),
                      icon: _sendBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.chat_rounded),
                      label: Text(
                        _sendBusy
                            ? 'Sending to BallChart…'
                            : 'Send report in BallChart messages',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: _shareButtonKey,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CoachTrainingAssignmentScreen.primaryColor,
                        side: BorderSide(
                          color: CoachTrainingAssignmentScreen.primaryColor.withValues(alpha: 0.5),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _pdfBusy ? null : _downloadPdf,
                      icon: _pdfBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CoachTrainingAssignmentScreen.primaryColor,
                              ),
                            )
                          : const Icon(Icons.ios_share_rounded),
                      label: Text(
                        _pdfBusy ? 'Generating…' : 'Share PDF outside the app',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use BallChart messages to send the report to the player inside the app. '
                      'Outside share is only for email / WhatsApp / Files.',
                      style: TextStyle(
                        color: CoachTrainingAssignmentScreen.outlineColor.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
