import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/profile_viewmodel.dart';
import '../../../core/widgets/battle/rank_progress_card.dart';
import '../../../core/widgets/home/stats_row.dart';
import '../../../core/widgets/profile/AchievementsSection/achievements_section.dart';
import '../../../core/widgets/profile/MyTeamsSection/my_teams_section.dart';
import '../../../core/widgets/profile/SettingsSection/settings_section.dart';
import '../../../core/widgets/profile/profile_header.dart';
import '../../../core/widgets/profile/profile_info_section.dart';
import '../../../core/widgets/dialogues/CreatePlayerDialog.dart';
import '../../../core/constants/colors.dart';
import '../../management/viewmodel/academy_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  bool _isCoachRole(String role) =>
      role == 'coach' || role == 'head_coach' || role == 'assistant_coach';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Consumer<ProfileViewmodel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator(color: AppColors.yellow)),
                );
              }
              if (viewModel.user == null) {
                final localUser = context.read<AcademyProvider>().currentUser;
                if (localUser != null) {
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Profile Preview', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text(localUser.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              localUser.role.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Login with account credentials to load full server profile data.',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const Center(
                  child: Text('Failed to load profile', style: TextStyle(color: Colors.white)),
                );
              }

              final user = viewModel.user!;
              final isCoach = _isCoachRole(user.role);

              return Column(
                children: [
                  ProfileHeader(user: user),
                  const SizedBox(height: 20),
                  StatsRow(user: user),
                  const SizedBox(height: 20),
                  ProfileInfoSection(user: user),
                  const SizedBox(height: 24),
                  RankProgressCard(user: user),
                  const SizedBox(height: 24),
                  const AchievementsSection(),
                  const SizedBox(height: 24),

                  // Coach: show managed teams & create player button
                  if (isCoach) ...[
                    MyTeamsSection(teams: user.assignedTeams),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Create Player Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const CreatePlayerDialog(),
                          );
                        },
                      ),
                    ),
                  ],

                  // Player: show team membership, coaching staff, teammates
                  if (user.role == 'player') ...[
                    if (user.teamName != null && user.teamName!.isNotEmpty)
                      _PlayerTeamCard(teamName: user.teamName!),
                    const SizedBox(height: 20),
                    const _PlayerCoachingStaff(),
                    const SizedBox(height: 20),
                    const _PlayerTeammates(),
                    const SizedBox(height: 24),
                  ],

                  const SettingsSection(),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// Team membership card for player profile
class _PlayerTeamCard extends StatelessWidget {
  final String teamName;
  const _PlayerTeamCard({required this.teamName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.yellow.withValues(alpha: 0.12),
            const Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.yellow, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MY TEAM',
                        style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 2),
                    Text(teamName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoTile('Players', '12', Icons.people_outline),
              const SizedBox(width: 20),
              _infoTile('Record', '8W - 2L', Icons.emoji_events_outlined),
              const SizedBox(width: 20),
              _infoTile('Age Group', 'U-19', Icons.cake_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white30, size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
        ],
      ),
    );
  }
}

// Coaching staff section for player profile
class _PlayerCoachingStaff extends StatelessWidget {
  const _PlayerCoachingStaff();

  @override
  Widget build(BuildContext context) {
    final staff = [
      {'name': 'Coach Carter', 'role': 'Head Coach', 'email': 'carter@academy.com', 'color': AppColors.yellow},
      {'name': 'Coach Smith', 'role': 'Asst. Coach', 'email': 'smith@academy.com', 'color': const Color(0xFF8B5CF6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.badge_rounded, color: Colors.white54, size: 18),
            SizedBox(width: 8),
            Text('Coaching Staff', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...staff.map((s) {
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
                    width: 44,
                    height: 44,
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
                        Text(s['name'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(s['role'] as String,
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(s['email'] as String,
                                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// Teammates section for player profile
class _PlayerTeammates extends StatelessWidget {
  const _PlayerTeammates();

  @override
  Widget build(BuildContext context) {
    final teammates = [
      {'name': 'Alex Johnson', 'position': 'Shooting Guard', 'number': '#7', 'stats': '22 PPG'},
      {'name': 'Sarah Williams', 'position': 'Small Forward', 'number': '#11', 'stats': '18 PPG'},
      {'name': 'Mike Chen', 'position': 'Center', 'number': '#34', 'stats': '15 PPG'},
      {'name': 'Emma Davis', 'position': 'Power Forward', 'number': '#22', 'stats': '12 PPG'},
      {'name': 'James Wilson', 'position': 'Point Guard', 'number': '#3', 'stats': '20 PPG'},
    ];

    final colors = [
      Colors.orangeAccent,
      Colors.lightBlueAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_rounded, color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            const Text('Teammates', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${teammates.length} players',
                style: const TextStyle(color: Colors.white30, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(teammates.length, (i) {
          final mate = teammates[i];
          final color = colors[i % colors.length];
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
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(mate['number']!,
                          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mate['name']!,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(mate['position']!,
                            style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(mate['stats']!,
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
