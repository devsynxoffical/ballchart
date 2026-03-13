import 'package:flutter/material.dart';
import 'widgets/hierarchy_management_widget.dart';
import 'package:provider/provider.dart';
import '../../../profile/viewmodel/profile_viewmodel.dart';
import '../../../../core/repositories/dashboard_repository.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamName;

  const TeamDetailScreen({super.key, required this.teamName});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final DashboardRepository _dashboardRepository = DashboardRepository();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewmodel>().user;
    final role = user?.role ?? 'player';
    final canRemove = role != 'player';

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.teamName, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardRepository.getCoachDashboard(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final teams = (data['teams'] as List? ?? [])
              .cast<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
          final team = teams.firstWhere(
            (t) => (t['name']?.toString().toLowerCase() ?? '') == widget.teamName.toLowerCase(),
            orElse: () => {},
          );
          final players = (team['players'] as List? ?? [])
              .cast<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
          final coachName = (team['coachStaffId'] is Map)
              ? (team['coachStaffId']['username']?.toString())
              : null;
          final assistantCoachName = (team['assistantCoachStaffId'] is Map)
              ? (team['assistantCoachStaffId']['username']?.toString())
              : null;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: HierarchyManagementWidget(
                    onPlayerAdded: (_) {},
                    role: role,
                    coachName: coachName,
                    assistantCoachName: assistantCoachName,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Team Roster',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (players.isEmpty)
                        const Text('No players found for this team.', style: TextStyle(color: Colors.white54)),
                      ...players.map((p) => _buildRosterItem(
                            p['username']?.toString() ?? 'Player',
                            p['position']?.toString() ?? '-',
                            '#',
                            canRemove,
                            () {},
                          )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRosterItem(String name, String position, String number, bool canRemove, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.grey[800], child: Text(number)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(position, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: onRemove,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
