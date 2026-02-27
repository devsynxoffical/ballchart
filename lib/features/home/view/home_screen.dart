import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/home/header.dart';
import '../../../core/widgets/home/stats_row.dart';
import '../../../features/profile/viewmodel/profile_viewmodel.dart';
import '../../../core/repositories/dashboard_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: const Header(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Consumer<ProfileViewmodel>(
            builder: (context, viewModel, child) {
              final user = viewModel.user;
              if (user == null) {
                return const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator(color: AppColors.yellow)),
                );
              }

              return FutureBuilder<Map<String, dynamic>>(
                future: DashboardRepository().getPlayerDashboard(),
                builder: (context, snapshot) {
                  final dashboard = snapshot.data ?? {};
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
                      StatsRow(user: user),
                      const SizedBox(height: 24),
                      if (team?['name'] != null || (user.teamName?.isNotEmpty ?? false))
                        _MyTeamCard(teamName: team?['name']?.toString() ?? user.teamName!),
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Coaching Staff', icon: Icons.badge_rounded),
                      const SizedBox(height: 12),
                      _CoachingStaffList(staff: staff),
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Teammates', icon: Icons.groups_rounded),
                      const SizedBox(height: 12),
                      _TeammatesList(teammates: teammates),
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Upcoming', icon: Icons.calendar_today_rounded),
                      const SizedBox(height: 12),
                      const _UpcomingSchedule(),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MyTeamCard extends StatelessWidget {
  final String teamName;
  const _MyTeamCard({required this.teamName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.yellow.withValues(alpha: 0.15),
            const Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.yellow, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MY TEAM',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _teamInfoChip(Icons.people_outline, '12 Players'),
                    const SizedBox(width: 12),
                    _teamInfoChip(Icons.emoji_events_outlined, '8W - 2L'),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
        ],
      ),
    );
  }

  Widget _teamInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 13),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}

class _CoachingStaffList extends StatelessWidget {
  final List<Map<String, dynamic>> staff;
  const _CoachingStaffList({required this.staff});

  @override
  Widget build(BuildContext context) {
    final normalized = staff.map((s) {
      final role = (s['role'] ?? '').toString();
      return {
        'name': s['username'] ?? 'Staff',
        'role': role.replaceAll('_', ' '),
        'color': role == 'assistant_coach' ? const Color(0xFF8B5CF6) : AppColors.yellow,
      };
    }).toList();

    if (normalized.isEmpty) {
      return const Text('No staff assigned.', style: TextStyle(color: Colors.white38));
    }

    return Column(
      children: normalized.map((s) {
        final color = s['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (s['name'] as String)[0],
                      style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s['role'] as String,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chat_bubble_outline_rounded, color: Colors.white.withValues(alpha: 0.2), size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TeammatesList extends StatelessWidget {
  final List<Map<String, dynamic>> teammates;
  const _TeammatesList({required this.teammates});

  @override
  Widget build(BuildContext context) {
    if (teammates.isEmpty) {
      return const Text('No teammates found.', style: TextStyle(color: Colors.white38));
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: teammates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final mate = teammates[index];
          final colors = [
            Colors.orangeAccent,
            Colors.lightBlueAccent,
            Colors.greenAccent,
            Colors.pinkAccent,
            Colors.cyanAccent,
          ];
          final color = colors[index % colors.length];
          return Container(
            width: 90,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#',
                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (mate['username']?.toString() ?? 'Player').split(' ').first,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  (mate['position']?.toString() ?? '-').split(' ').first,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UpcomingSchedule extends StatelessWidget {
  const _UpcomingSchedule();

  @override
  Widget build(BuildContext context) {
    final events = [
      {'title': 'Team Practice', 'time': 'Today, 4:00 PM', 'icon': Icons.fitness_center, 'color': AppColors.green},
      {'title': 'Match vs Rising Stars', 'time': 'Wed, 6:00 PM', 'icon': Icons.sports_basketball, 'color': AppColors.yellow},
      {'title': 'Strategy Review', 'time': 'Fri, 3:00 PM', 'icon': Icons.analytics_outlined, 'color': const Color(0xFF3B82F6)},
    ];

    return Column(
      children: events.map((e) {
        final color = e['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(e['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['title'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e['time'] as String,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.15), size: 14),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
