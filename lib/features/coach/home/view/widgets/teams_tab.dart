import 'package:flutter/material.dart';
import 'package:ballchart/core/widgets/dialogues/CreateTeamDialog.dart';
import 'package:ballchart/features/coach/team_details/view/team_detail_screen.dart';
import 'package:ballchart/features/player_development/view/coach_training_assignment_screen.dart';
import 'package:ballchart/core/models/battle_model.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/core/services/api_service.dart';
import '../../../../management/viewmodel/academy_provider.dart';
import 'package:provider/provider.dart';

class TeamsTab extends StatefulWidget {
  const TeamsTab({super.key});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  // BallChart Redesign Tokens - Same as Admin Panel
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithRetry();
    });
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        await context.read<AcademyProvider>().loadCoachDashboard(force: true);
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            String errorMessage = e.toString();
            
            // Handle specific error cases
            if (errorMessage.contains('401') || errorMessage.contains('Unauthorized')) {
              errorMessage = 'Authentication failed. Please log in again.';
            } else if (errorMessage.contains('403') || errorMessage.contains('Forbidden')) {
              errorMessage = 'Access denied. You do not have permission to view coach data.';
            } else if (errorMessage.contains('Cannot read properties of undefined')) {
              errorMessage = 'Connection error. Please check your internet connection.';
            } else if (errorMessage.contains('Network')) {
              errorMessage = 'Network error. Please check your connection and try again.';
            } else if (errorMessage.contains('timeout')) {
              errorMessage = 'Request timeout. Please try again.';
            } else {
              errorMessage = errorMessage.replaceAll('Exception: ', '');
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load coach data: $errorMessage'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _loadDataWithRetry(),
                ),
              ),
            );
          }
        } else {
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        // Show loading state
        if (provider.isCoachLoading) {
          return const SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Loading Coach Dashboard...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          );
        }

        // Only block on errors when coach dashboard did not load (avoid stale global errors from admin/other flows).
        if (provider.error != null && provider.coachDashboard == null && !provider.isCoachLoading) {
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
                          Text(
                            'Error Loading Data',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 20, 
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.error!,
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

        // Show empty state
        if (provider.coachDashboard == null) {
          return const SizedBox(
            height: 400,
            child: Center(
              child: Text(
                'No coach data available',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final dashboard = provider.coachDashboard!;
        final allTeams = (dashboard['teams'] as List? ?? [])
            .map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{})
            .where((m) => m.isNotEmpty)
            .toList();

        final teams = allTeams;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operations Hub Header
              const Text(
                'OPERATIONS HUB // 04.24',
                style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 4),
              Text(
                teams.isEmpty ? 'NO TEAMS ASSIGNED' : 'MY TEAMS (${teams.length})',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
              ),
              if (teams.isEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'You haven\'t been assigned to any team yet. Contact your academy admin to get team assignments.',
                  style: const TextStyle(color: outlineColor, fontSize: 14),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Teams under your command',
                  style: const TextStyle(color: outlineColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 24),

              _buildAssignTrainingEntry(),
              const SizedBox(height: 32),

              // Active Squads Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ACTIVE SQUADS',
                    style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  Text(
                    'TAP A TEAM FOR DETAILS',
                    style: TextStyle(color: outlineColor.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: teams.map((team) => _buildSquadCard(team, dashboard, provider)).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Bento Grid - Strategic Intelligence
              _buildNextBattleCard(dashboard),
              const SizedBox(height: 16),
              _buildPerformanceRow(teams),
              const SizedBox(height: 16),
              _buildIntelligenceFeed(dashboard, teams),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignTrainingEntry() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const CoachTrainingAssignmentScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: primaryColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ASSIGN TRAINING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Space Grotesk',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pick player, focus & drill — players earn points when they complete sessions.',
                        style: TextStyle(color: outlineColor.withOpacity(0.95), fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: primaryColor, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _staffRefId(dynamic v) {
    if (v == null) return null;
    if (v is Map) return v['_id']?.toString();
    return v.toString();
  }

  Map<String, int> _aggregatePlayerStats(Map<String, dynamic> team) {
    int matches = 0, wins = 0;
    for (final p in (team['players'] as List?) ?? []) {
      if (p is! Map) continue;
      final stats = p['stats'];
      if (stats is Map) {
        matches += ((stats['matchesPlayed'] as num?) ?? 0).toInt();
        wins += ((stats['wins'] as num?) ?? 0).toInt();
      }
    }
    return {'matches': matches, 'wins': wins};
  }

  String _teamWinRateLabel(Map<String, dynamic> team) {
    final s = _aggregatePlayerStats(team);
    final m = s['matches'] ?? 0;
    final w = s['wins'] ?? 0;
    if (m <= 0) return '—';
    return '${((w / m) * 100).round()}%';
  }

  String _profileRankLabel(Map<String, dynamic> dashboard, AcademyProvider provider) {
    final profile = dashboard['profile'];
    if (profile is Map && profile['rank'] != null) {
      return '#${profile['rank']}';
    }
    final r = provider.currentUser?.rank;
    if (r != null && r > 0) return '#$r';
    return '—';
  }

  int _totalPlayersAcross(List<Map<String, dynamic>> teams) {
    var n = 0;
    for (final t in teams) {
      n += ((t['players'] as List?)?.length ?? 0);
    }
    return n;
  }

  Map<String, dynamic>? _topPerformerFromTeams(List<Map<String, dynamic>> teams) {
    Map<String, dynamic>? best;
    var bestPts = -1;
    for (final t in teams) {
      for (final p in (t['players'] as List?) ?? []) {
        if (p is! Map) continue;
        final stats = p['stats'];
        final pts = stats is Map ? ((stats['points'] as num?) ?? 0).toInt() : 0;
        if (pts > bestPts) {
          bestPts = pts;
          best = Map<String, dynamic>.from(p.map((k, v) => MapEntry(k.toString(), v)));
          best['_squadName'] = t['name']?.toString() ?? '';
        }
      }
    }
    if (best == null || bestPts < 0) return null;
    return best;
  }

  String _formatBattleTime(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '';
    final local = d.toLocal();
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSquadCard(Map<String, dynamic> team, Map<String, dynamic> dashboard, AcademyProvider provider) {
    final cv = team['colorValue'];
    final color = Color(cv is int ? cv : 0xFFFFD900);
    final currentUser = provider.currentUser;
    final coachId = _staffRefId(team['coachStaffId']);
    final asstId = _staffRefId(team['assistantCoachStaffId']);
    final isHeadCoach = coachId != null && coachId == currentUser?.id;
    final isAsstCoach = asstId != null && asstId == currentUser?.id;
    final role = isHeadCoach ? 'HEAD COACH' : (isAsstCoach ? 'ASSISTANT COACH' : 'STAFF COHORT');
    final teamId = team['_id']?.toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailScreen(
              teamId: teamId,
              teamName: team['name']?.toString() ?? '',
            ),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), 
              blurRadius: 20, 
              offset: const Offset(0, 10)
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.sports_basketball, size: 100, color: Colors.white.withOpacity(0.03)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team['name']?.toString().toUpperCase() ?? 'SQUAD',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  team['ageGroup']?.toString().toUpperCase() ?? 'ELITE DIVISION',
                  style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniMetric('${(team['players'] as List?)?.length ?? 0}', 'PLAYERS', primaryColor),
                    _miniMetric(_teamWinRateLabel(team), 'WIN RATE', Colors.white),
                    _miniMetric(_profileRankLabel(dashboard, provider), 'RANK', const Color(0xFF28D8FF)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
        Text(label, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAddSquadCard() {
    return GestureDetector(
      onTap: () => _showCreateTeamDialog(),
      child: Container(
        width: 180,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: outlineColor.withOpacity(0.2), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: outlineColor.withOpacity(0.3))),
              child: const Icon(Icons.add, color: outlineColor),
            ),
            const SizedBox(height: 12),
            const Text(
              'REGISTER\nNEW SQUAD',
              textAlign: TextAlign.center,
              style: TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextBattleCard(Map<String, dynamic> dashboard) {
    final raw = dashboard['upcomingBattles'] as List<dynamic>? ?? [];
    final battles = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final next = battles.isNotEmpty ? battles.first : null;
    final subtitle = next == null
        ? 'NO MATCHES ON THE CALENDAR'
        : '${(next['status'] ?? 'pending').toString().toUpperCase()} · ${_formatBattleTime(next['dateTime'])}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineColor.withOpacity(0.1)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEXT GAME',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: next != null ? primaryColor : outlineColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      next != null ? 'GAME' : '',
                      style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      next != null ? BattleModel.titleFromMap(next) : '—',
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineColor.withOpacity(0.12)),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  next != null
                      ? 'Scheduled ${_formatBattleTime(next['dateTime'])}'
                      : 'When your academy schedules a game, it will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: outlineColor.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topPerformerLeadAvatar(Map<String, dynamic> top) {
    final resolved = ApiService.resolveMediaUrl(top['profileImageUrl']?.toString());
    if (resolved.isNotEmpty && resolved.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          resolved,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: surfaceHighest, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person, color: Colors.white24, size: 28),
          ),
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: surfaceHighest, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.person, color: Colors.white24, size: 28),
    );
  }

  Widget _buildPerformanceRow(List<Map<String, dynamic>> teams) {
    final top = _topPerformerFromTeams(teams);
    final stats = top != null && top['stats'] is Map ? Map<String, dynamic>.from(top['stats'] as Map) : <String, dynamic>{};
    final pts = (stats['points'] as num?)?.toInt() ?? 0;
    final mp = (stats['matchesPlayed'] as num?)?.toInt() ?? 0;
    final wins = (stats['wins'] as num?)?.toInt() ?? 0;
    final winRate = mp > 0 ? (wins / mp).clamp(0.0, 1.0) : 0.0;
    final name = (top?['username'] ?? top?['name'] ?? '—').toString();
    final pos = (top?['position'] ?? '—').toString();
    final squad = (top?['_squadName'] ?? '').toString();

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceHigh,
              borderRadius: BorderRadius.circular(24),
              border: const Border(left: BorderSide(color: primaryColor, width: 4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOP PERFORMER', style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Icon(Icons.star, color: primaryColor, size: 14),
                  ],
                ),
                const SizedBox(height: 16),
                if (top == null)
                  Text(
                    'Roster stats will show your leading scorer once players have recorded games.',
                    style: TextStyle(color: outlineColor.withOpacity(0.9), fontSize: 12),
                  )
                else ...[
                  Row(
                    children: [
                      _topPerformerLeadAvatar(top),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              squad.isNotEmpty ? '$pos · $squad' : pos,
                              style: const TextStyle(color: outlineColor, fontSize: 8),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'PTS (SEASON)',
                          style: TextStyle(color: outlineColor, fontSize: 7, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('$pts', style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'WIN RATE (GAMES)',
                          style: TextStyle(color: outlineColor, fontSize: 7, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${(winRate * 100).round()}%', style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: mp > 0 ? winRate : 0,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      color: primaryColor,
                      minHeight: 3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntelligenceFeed(Map<String, dynamic> dashboard, List<Map<String, dynamic>> teams) {
    final totalP = _totalPlayersAcross(teams);
    final battles = (dashboard['upcomingBattles'] as List?) ?? [];
    final nextBattle = battles.isNotEmpty && battles.first is Map ? Map<String, dynamic>.from(battles.first as Map) : null;
    final top = _topPerformerFromTeams(teams);
    final topName = top != null ? (top['username'] ?? top['name'] ?? 'Player').toString() : '';

    final lines = <(String, Color, String)>[
      (
        '${teams.length} active squad${teams.length == 1 ? '' : 's'} · $totalP player${totalP == 1 ? '' : 's'} rostered',
        outlineColor,
        'LIVE',
      ),
      (
        nextBattle != null
            ? 'Next: ${BattleModel.titleFromMap(nextBattle)} @ ${_formatBattleTime(nextBattle['dateTime'])}'
            : 'No upcoming games in the next window.',
        const Color(0xFF28D8FF),
        'OPS',
      ),
      (
        top != null ? 'Scoring: $topName leads your squads (PTS from recorded games).' : 'Add athletes and log games to unlock insights.',
        primaryColor,
        'INSIGHT',
      ),
    ];

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
          const Row(
            children: [
              Icon(Icons.notifications_none, color: outlineColor, size: 18),
              SizedBox(width: 8),
              Text('INTELLIGENCE FEED', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
            ],
          ),
          const SizedBox(height: 16),
          for (final line in lines) _feedItem(line.$1, line.$2, line.$3),
        ],
      ),
    );
  }

  Widget _feedItem(String text, Color dotColor, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(time, style: const TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCreateTeamDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateTeamDialog(
        onTeamCreated: (name, age, color, logoPath, coachId, assistantId) async {
          final provider = context.read<AcademyProvider>();
          await provider.addTeamToBackend(
            Team(
              id: provider.nextId('t'),
              name: name,
              players: const [],
              ageGroup: age,
              colorValue: color.toARGB32(),
              logoPath: logoPath,
              coachStaffId: coachId,
              assistantCoachStaffId: assistantId,
            ),
          );
          if (context.mounted) Navigator.pop(context);
          // Teams are now handled by AcademyProvider
        },
      ),
    );
  }
}
