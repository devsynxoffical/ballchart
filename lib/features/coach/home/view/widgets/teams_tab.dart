import 'package:flutter/material.dart';
import 'package:courtiq/core/widgets/dialogues/CreateTeamDialog.dart';
import 'package:courtiq/core/widgets/home/team_card.dart';
import 'package:courtiq/core/models/local_academy_models.dart';
import 'package:courtiq/features/coach/team_details/view/team_detail_screen.dart';
import 'package:courtiq/core/repositories/dashboard_repository.dart';
import 'package:courtiq/features/management/viewmodel/academy_provider.dart';
import 'package:provider/provider.dart';

class TeamsTab extends StatefulWidget {
  const TeamsTab({super.key});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  final DashboardRepository _dashboardRepository = DashboardRepository();
  late Future<List<Map<String, dynamic>>> _teamsFuture;

  @override
  void initState() {
    super.initState();
    _teamsFuture = _loadTeams();
  }

  Future<List<Map<String, dynamic>>> _loadTeams() async {
    final data = await _dashboardRepository.getCoachDashboard();
    final teams = (data['teams'] as List? ?? [])
        .cast<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    return teams;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _teamsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final teams = snapshot.data!;
              if (teams.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No teams available yet.', style: TextStyle(color: Colors.white54)),
                );
              }
              return Column(
                children: teams
                    .map((team) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamDetailScreen(teamName: team['name']?.toString() ?? ''),
                                ),
                              );
                            },
                            child: TeamCard(
                              title: team['name']?.toString() ?? 'Team',
                              members: '${(team['players'] as List? ?? []).length} members',
                              icon: Icons.shield_rounded,
                              iconBg: Color((team['colorValue'] is int) ? team['colorValue'] as int : 0xFFF59E0B),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => CreateTeamDialog(
                    onTeamCreated: (name, age, color, logoPath) async {
                      final provider = context.read<AcademyProvider>();
                      await provider.addTeamToBackend(
                        Team(
                          id: provider.nextId('t'),
                          name: name,
                          players: const [],
                          ageGroup: age,
                          colorValue: color.toARGB32(),
                          logoPath: logoPath,
                        ),
                      );
                      if (mounted) {
                        setState(() {
                          _teamsFuture = _loadTeams();
                        });
                      }
                    },
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('+ Create New Team'),
            ),
          ),
        ],
      ),
    );
  }
}
