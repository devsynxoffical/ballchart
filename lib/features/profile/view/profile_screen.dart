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
import '../../../core/repositories/dashboard_repository.dart';

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
                return const Center(
                  child: Text('Failed to load profile', style: TextStyle(color: Colors.white)),
                );
              }

              final user = viewModel.user!;
              final isCoach = _isCoachRole(user.role);
              final canCreatePlayer = user.role == 'admin' ||
                  user.role == 'head_coach' ||
                  (user.permissions?['createPlayer'] == true);

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
                    if (canCreatePlayer)
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
                    _PlayerDashboardSections(user: user),
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
  final int playersCount;
  final String ageGroup;
  final String recordText;
  const _PlayerTeamCard({
    required this.teamName,
    required this.playersCount,
    required this.ageGroup,
    required this.recordText,
  });

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
              _infoTile('Players', '$playersCount', Icons.people_outline),
              const SizedBox(width: 20),
              _infoTile('Record', recordText, Icons.emoji_events_outlined),
              const SizedBox(width: 20),
              _infoTile('Age Group', ageGroup, Icons.cake_outlined),
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

class _PlayerDashboardSections extends StatelessWidget {
  final user;
  const _PlayerDashboardSections({required this.user});

  @override
  Widget build(BuildContext context) {
    final repo = DashboardRepository();
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.getPlayerDashboard(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: AppColors.yellow)),
          );
        }

        final data = snapshot.data!;
        final team = (data['team'] as Map?)?.cast<String, dynamic>();
        final teammates = (data['teammates'] as List? ?? [])
            .cast<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        final coachingStaff = (data['coachingStaff'] as List? ?? [])
            .cast<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlayerTeamCard(
              teamName: (team?['name']?.toString().isNotEmpty == true)
                  ? team!['name'].toString()
                  : (user.teamName ?? 'Unassigned Team'),
              playersCount: (team?['players'] as List?)?.length ?? 0,
              ageGroup: team?['ageGroup']?.toString() ?? 'Open',
              recordText: '${user.stats['wins'] ?? 0}W',
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.badge_rounded, color: Colors.white54, size: 18),
                SizedBox(width: 8),
                Text('Coaching Staff', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (coachingStaff.isEmpty)
              const Text('No coaching staff assigned', style: TextStyle(color: Colors.white38)),
            ...coachingStaff.map((staff) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${staff['username'] ?? 'Staff'} • ${staff['role'] ?? ''}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.groups_rounded, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                const Text('Teammates', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${teammates.length} players', style: const TextStyle(color: Colors.white30, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            ...teammates.map((mate) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            mate['username']?.toString() ?? 'Teammate',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          mate['position']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}
