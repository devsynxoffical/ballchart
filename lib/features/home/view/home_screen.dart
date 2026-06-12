import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/home/header.dart';
import '../../../features/management/viewmodel/academy_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryColor = Color(0xFFFFD900); // FDB927 equivalent
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF201F1F);
  static const Color surfaceLow = Color(0xFF1C1B1B);
  static const Color outlineColor = Color(0xFF9D8F79);

  Widget _buildActiveDivision(Map<String, dynamic> dashboard) {
    final playerData = dashboard['player'] ?? {};
    final division = playerData['division'] ?? playerData['league'];
    final rank = playerData['divisionRank'] ?? playerData['rank'];
    final gamesPlayed = playerData['gamesPlayed'];
    final winLoss = playerData['record'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDB927).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE DIVISION',
                style: const TextStyle(
                  color: outlineColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (rank != null && '$rank'.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDB927).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Color(0xFFFDB927),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDB927).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.leaderboard, color: Color(0xFFFDB927), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (division != null && '$division'.trim().isNotEmpty) ? '$division' : 'Division',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _divisionSubtitle(gamesPlayed, winLoss),
                      style: const TextStyle(
                        color: outlineColor,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCategories(Map<String, dynamic> dashboard) {
    final team = dashboard['team'] as Map? ?? {};
    final category = team['category'] ?? team['division'];
    final level = team['level'] ?? team['tier'];
    final playersList = team['players'];
    final members = team['memberCount'] ?? (playersList is List ? playersList.length : null);
    final founded = team['founded'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEAM CATEGORIES',
            style: const TextStyle(
              color: outlineColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _categoryCard('CATEGORY', _strOrDash(category), Icons.category),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _categoryCard('LEVEL', _strOrDash(level), Icons.trending_up),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _categoryCard('MEMBERS', members != null ? '$members' : '—', Icons.group),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _categoryCard('FOUNDED', _strOrDash(founded), Icons.calendar_today),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _strOrDash(dynamic v) {
    if (v == null) return '—';
    final s = '$v'.trim();
    return s.isEmpty ? '—' : s;
  }

  String _divisionSubtitle(dynamic gamesPlayed, dynamic winLoss) {
    final gp = gamesPlayed != null ? '$gamesPlayed'.trim() : '';
    final wl = winLoss != null ? '$winLoss'.trim() : '';
    if (gp.isEmpty && wl.isEmpty) return 'No league record yet';
    if (wl.isEmpty) return gp.isEmpty ? '—' : '$gp games';
    return '${gp.isEmpty ? '—' : '$gp games'} • $wl record';
  }

  Widget _categoryCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFDB927), size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: outlineColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Space Grotesk',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Header(),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final provider = Provider.of<AcademyProvider>(context, listen: false);
            await provider.loadPlayerDashboard(force: true);
          },
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Consumer<AcademyProvider>(
            builder: (context, provider, child) {
              if (provider.playerDashboard == null && !provider.isPlayerLoading) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  provider.loadPlayerDashboard(force: true);
                });
              }

              if (provider.isPlayerLoading || provider.playerDashboard == null) {
                return const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator(color: primaryColor)),
                );
              }

              final dashboard = provider.playerDashboard!;
              final team = (dashboard['team'] as Map?)?.cast<String, dynamic>();
              final staff = (dashboard['coachingStaff'] as List? ?? [])
                  .cast<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();
              final teammates = (dashboard['teammates'] as List? ?? [])
                  .cast<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();

              return Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const SizedBox(height: 8),
                   _buildStatsRow(dashboard['player'] ?? {}),
                   const SizedBox(height: 32),
                   _buildActiveDivision(dashboard),
                   const SizedBox(height: 32),
                   _buildTeamCategories(dashboard),
                   const SizedBox(height: 32),
                   _buildTeamBanner(
                     teamName: team?['name']?.toString() ?? 'UNASSIGNED',
                     playerCount: () {
                       final pl = team?['players'];
                       return pl is List ? pl.length : null;
                     }(),
                     record: team?['record']?.toString(),
                     streak: team?['streak']?.toString(),
                   ),
                   const SizedBox(height: 32),
                   _buildSectionTitle('Upcoming Schedule', null, null),
                   const SizedBox(height: 16),
                   _UpcomingSchedule(events: (dashboard['upcomingEvents'] as List?) ?? const []),
                   const SizedBox(height: 32),
                   _buildSectionTitle('Starting Lineup', null, null),
                   const SizedBox(height: 16),
                   _buildTeammatesScroller(teammates),
                   const SizedBox(height: 32),
                   _buildSectionTitle('Coaching Staff', null, null),
                   const SizedBox(height: 16),
                   _buildCoachingStaff(staff),
                   const SizedBox(height: 100),
                 ],
              );
            },
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? actionText, VoidCallback? onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Space Grotesk',
            letterSpacing: 0.5,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow(dynamic user) {
    final stats = user['stats'] ?? user;
    final points = stats['points'] ?? stats['pts'] ?? user['points'] ?? user['pts'] ?? '—';
    final rebounds = stats['rebounds'] ?? stats['reb'] ?? user['rebounds'] ?? user['reb'] ?? '—';
    final assists = stats['assists'] ?? stats['ast'] ?? user['assists'] ?? user['ast'] ?? '—';

    return Row(
      children: [
        Expanded(child: _statCard('POINTS', points.toString())),
        const SizedBox(width: 16),
        Expanded(child: _statCard('REBOUNDS', rebounds.toString())),
        const SizedBox(width: 16),
        Expanded(child: _statCard('ASSISTS', assists.toString())),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFFFDB927), width: 4)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
        ],
      ),
    );
  }

  Widget _buildTeamBanner({required String teamName, int? playerCount, String? record, String? streak}) {
    final count = playerCount ?? 0;
    final rec = record ?? '—';
    final str = streak ?? '—';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.2), const Color(0xFF14D7FF).withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: surfaceLow,
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ACTIVE DIVISION', style: TextStyle(color: Color(0xFFFFBA29), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(teamName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('$count PLAYERS', style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RECORD', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(rec, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STREAK', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(str, style: const TextStyle(color: Color(0xFF14D7FF), fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primaryColor, Color(0xFFFFDCA3)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {},
                  child: const Text('ROSTER', style: TextStyle(color: Color(0xFF422D00), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeammatesScroller(List<Map<String, dynamic>> teammates) {
    if (teammates.isEmpty) {
      return const Text('No roster data.', style: TextStyle(color: outlineColor));
    }
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: teammates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final mate = teammates[index];
          return _TeammateCard(mate: mate);
        },
      ),
    );
  }

  Widget _buildCoachingStaff(List<Map<String, dynamic>> staff) {
    if (staff.isEmpty) return const Text('No staff data.', style: TextStyle(color: outlineColor));
    return Column(
      children: staff.map((s) => _StaffCard(staff: s)).toList(),
    );
  }
}

class _UpcomingSchedule extends StatelessWidget {
  const _UpcomingSchedule({required this.events});

  final List<dynamic> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'No upcoming events scheduled.',
          style: TextStyle(color: Color(0xFF9D8F79), fontSize: 14),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < events.length && i < 8; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _scheduleItem(events[i]),
        ],
      ],
    );
  }

  Widget _scheduleItem(dynamic raw) {
    final m = raw is Map ? raw.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};
    final title = m['title']?.toString() ?? m['name']?.toString() ?? 'Event';
    final subtitle = m['subtitle']?.toString() ?? m['location']?.toString() ?? '';
    final dt = m['dateTime'] ?? m['date'] ?? m['startsAt'];
    DateTime? d;
    if (dt is String) {
      d = DateTime.tryParse(dt);
    }
    final day = d != null ? '${d.day}'.padLeft(2, '0') : '—';
    final month = d != null ? _monthShort(d.month) : '—';
    final icon = (m['type']?.toString() == 'training') ? Icons.fitness_center : Icons.event;
    const accColor = Color(0xFF14D7FF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: accColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(day, style: const TextStyle(color: accColor, fontSize: 16, fontWeight: FontWeight.bold, height: 1.1)),
                Text(month, style: const TextStyle(color: accColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF9D8F79), fontSize: 12)),
                ],
              ],
            ),
          ),
          Icon(icon, color: accColor, size: 24),
        ],
      ),
    );
  }

  String _monthShort(int m) {
    const names = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return names[(m - 1).clamp(0, 11)];
  }
}

class _TeammateCard extends StatelessWidget {
  final Map<String, dynamic> mate;
  const _TeammateCard({required this.mate});

  @override
  Widget build(BuildContext context) {
    final name = (mate['username']?.toString() ?? 'Player').split(' ').first;
    final position = (mate['position']?.toString() ?? 'Unknown Position');
    final number = mate['jersey']?.toString() ?? '00';

    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF353534), // surface-container-highest
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: Color(0xFFFDB927), width: 2)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Text(number, style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF504533).withOpacity(0.5)),
                  ),
                  child: const Center(child: Icon(Icons.person_outline, color: Color(0xFFFDB927), size: 28)),
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(position.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFDB927), fontFamily: 'Space Grotesk', fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    final name = staff['name']?.toString() ?? 'Unknown Staff';
    final role = staff['role']?.toString() ?? 'Staff';
    final isHC = role.toLowerCase().contains('head') || role.toLowerCase().contains('hc');
    final roleLabel = role.replaceAll('_', ' ').toUpperCase();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHC ? const Color(0xFF422D00) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHC ? const Color(0xFFFDB927) : Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isHC ? const Color(0xFFFDB927) : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.split(' ').map((e) => e[0]).take(2).join().toUpperCase(),
                style: TextStyle(color: isHC ? const Color(0xFF422D00) : const Color(0xFFFDB927), fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(roleLabel.toUpperCase(), style: const TextStyle(color: Color(0xFF9D8F79), fontSize: 10, fontFamily: 'Space Grotesk', letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.chat_bubble_outline, color: Color(0xFFFFBA29), size: 16)),
          ),
        ],
      ),
    );
  }
}
