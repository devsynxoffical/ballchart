import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/core/constants/relentless_program.dart';
import 'package:ballchart/core/models/development_models.dart';
import 'package:ballchart/core/repositories/development_repository.dart';
import 'package:ballchart/core/services/api_service.dart';
import 'package:ballchart/features/player_development/view/my_development_screen.dart';
import 'package:ballchart/features/player_development/view/training_completion_report_screen.dart';
import '../../management/viewmodel/academy_provider.dart';

class PlayerStatsTab extends StatefulWidget {
  const PlayerStatsTab({super.key});

  @override
  PlayerStatsTabState createState() => PlayerStatsTabState();
}

class PlayerStatsTabState extends State<PlayerStatsTab> {
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color outlineColor = Color(0xFF9D8F79);

  final DevelopmentRepository _devRepo = DevelopmentRepository();

  int _trainingDevPoints = 0;
  int _pendingTraining = 0;
  TrainingAssignmentDto? _lastCompletedTraining;
  bool _trainingLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithRetry();
    });
  }

  /// Called when switching back to the HOME tab so points stay up to date.
  Future<void> refreshTrainingSummary() async {
    await _loadTrainingSummary();
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    final academy = context.read<AcademyProvider>();
    for (var i = 0; i < retryCount; i++) {
      await academy.loadPlayerDashboard(force: i > 0);
      if (!mounted) return;
      final p = context.read<AcademyProvider>();
      if (p.playerDashboard != null) {
        await _loadTrainingSummary();
        return;
      }
      if (i < retryCount - 1) {
        await Future.delayed(Duration(seconds: 1 + i));
      }
    }
  }

  Future<void> _loadTrainingSummary() async {
    if (!mounted) return;
    setState(() => _trainingLoading = true);
    try {
      final points = await _devRepo.fetchMyPoints();
      final list = await _devRepo.fetchMyAssignments();
      if (!mounted) return;
      TrainingAssignmentDto? lastDone;
      for (final a in list) {
        if (a.status != 'completed') continue;
        if (lastDone == null) {
          lastDone = a;
          continue;
        }
        final ca = a.completedAt;
        final cb = lastDone.completedAt;
        if (ca != null && (cb == null || ca.isAfter(cb))) {
          lastDone = a;
        }
      }
      setState(() {
        _trainingDevPoints = points;
        _pendingTraining = list.where((a) => a.status == 'pending').length;
        _lastCompletedTraining = lastDone;
        _trainingLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _trainingLoading = false;
        });
      }
    }
  }

  Future<void> _openTraining() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const MyDevelopmentScreen()),
    );
    if (mounted) await _loadTrainingSummary();
  }

  void _openReport(TrainingAssignmentDto a) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TrainingCompletionReportScreen(assignment: a),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        if (provider.isPlayerLoading) {
          return const SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Loading your dashboard…', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          );
        }

        final err = provider.playerDashboardError;
        if (err != null) {
          return SizedBox(
            height: 400,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceHigh,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: outlineColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Couldn\'t load dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            err,
                            style: const TextStyle(color: outlineColor, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => _loadDataWithRetry(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'RETRY',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (provider.playerDashboard == null) {
          return const SizedBox(
            height: 400,
            child: Center(
              child: Text(
                'No dashboard data yet',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final dashboard = provider.playerDashboard!;
        final playerData = dashboard['player'] as Map<String, dynamic>? ?? {};
        final battleStats = _asStringMap(dashboard['battleStats']);

        return RefreshIndicator(
          color: primaryColor,
          onRefresh: () async {
            await provider.loadPlayerDashboard(force: true);
            await _loadTrainingSummary();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYER PERFORMANCE // ${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PLAYER OVERVIEW',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
                ),
                const SizedBox(height: 24),
                _buildPlayerIdentityRow(playerData),
                const SizedBox(height: 24),
                _buildTrainingAssignmentsCard(),
                const SizedBox(height: 32),
                _buildPlayerStatsRow(playerData),
                const SizedBox(height: 24),
                _buildBattleSummary(battleStats),
                const SizedBox(height: 24),
                _buildRecentGames(playerData, battleStats),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrainingAssignmentsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRAINING & ASSIGNMENTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Space Grotesk',
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      RelentlessProgram.subtitle,
                      style: TextStyle(
                        color: outlineColor.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (_trainingLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Development points',
                      style: TextStyle(color: outlineColor.withOpacity(0.95), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_trainingDevPoints',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                    Text(
                      'From completed coach assignments',
                      style: TextStyle(color: outlineColor.withOpacity(0.8), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_pendingTraining',
                      style: const TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'pending',
                      style: TextStyle(color: outlineColor.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_lastCompletedTraining != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Last completed · +${_lastCompletedTraining!.pointsValue} pts',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_lastCompletedTraining!.focusArea} · ${_lastCompletedTraining!.drillName}',
                    style: TextStyle(color: outlineColor.withOpacity(0.95), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                      ),
                      onPressed: () => _openReport(_lastCompletedTraining!),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('View completion PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _openTraining,
              icon: const Icon(Icons.fitness_center_rounded),
              label: const Text('OPEN MY TRAINING', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _asStringMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  Widget _buildPlayerIdentityRow(Map<String, dynamic> playerData) {
    final raw = playerData['profileImageUrl']?.toString().trim();
    final url = (raw != null && raw.isNotEmpty) ? ApiService.resolveMediaUrl(raw) : '';
    final hasImg = url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:'));
    final name = (playerData['username'] ?? 'Player').toString();
    final pos = (playerData['position'] ?? '').toString();
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'P';

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withOpacity(0.35), width: 2),
            color: surfaceHigh,
          ),
          child: ClipOval(
            child: hasImg
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: 72,
                    height: 72,
                    errorBuilder: (_, __, ___) => Center(child: Text(initial, style: const TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.w900))),
                  )
                : Center(child: Text(initial, style: const TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.w900))),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (pos.isNotEmpty)
                Text(
                  pos.toUpperCase(),
                  style: const TextStyle(color: outlineColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerStatsRow(Map<String, dynamic> playerData) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('PPG', playerData['ppg']?.toString() ?? '0.0', primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('APG', playerData['apg']?.toString() ?? '0.0', const Color(0xFF28D8FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('RPG', playerData['rpg']?.toString() ?? '0.0', const Color(0xFF8B5CF6)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Space Grotesk',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: outlineColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleSummary(Map<String, dynamic> battleStats) {
    final mp = battleStats['matchesPlayed'] ?? battleStats['matches'] ?? 0;
    final wins = battleStats['wins'] ?? 0;
    final pts = battleStats['points'] ?? battleStats['totalPoints'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineColor.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(child: _miniStat('Games', '$mp')),
          Expanded(child: _miniStat('Wins', '$wins')),
          Expanded(child: _miniStat('Battle pts', '$pts')),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: outlineColor, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRecentGames(Map<String, dynamic> playerData, Map<String, dynamic> battleStats) {
    final raw = battleStats['recentGames'] ?? playerData['recentGames'];
    final List<dynamic> games = raw is List ? raw : const [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT GAMES',
            style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          if (games.isEmpty)
            Text(
              'No recent games yet. Stats will appear here after official games.',
              style: TextStyle(color: outlineColor.withOpacity(0.95), fontSize: 14, height: 1.4),
            )
          else
            ...games.take(8).map((g) => _buildGameRow(_asStringMap(g))),
        ],
      ),
    );
  }

  Widget _buildGameRow(Map<String, dynamic> g) {
    final opponent = g['opponent']?.toString() ?? g['title']?.toString() ?? 'Game';
    final result = (g['result']?.toString() ?? g['outcome']?.toString() ?? '').toUpperCase();
    final line = g['statLine']?.toString() ?? g['summary']?.toString() ?? '';
    final won = result == 'W' || result == 'WIN';
    final lost = result == 'L' || result == 'LOSS';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.isNotEmpty)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: won
                    ? primaryColor.withOpacity(0.2)
                    : lost
                        ? Colors.red.withOpacity(0.2)
                        : surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  result.length > 3 ? result.substring(0, 1) : result,
                  style: TextStyle(
                    color: won ? primaryColor : (lost ? Colors.red : outlineColor),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (result.isNotEmpty) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opponent, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                if (line.isNotEmpty)
                  Text(line, style: const TextStyle(color: outlineColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
