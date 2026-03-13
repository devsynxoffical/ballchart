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

  String? _extractStaffName(
    dynamic staffRef,
    List<Map<String, dynamic>> staffList,
  ) {
    if (staffRef is Map) {
      final mapped = staffRef.cast<String, dynamic>();
      final username = mapped['username']?.toString();
      if (username != null && username.isNotEmpty) return username;
      final id = mapped['_id']?.toString();
      if (id != null && id.isNotEmpty) {
        final matched = staffList.where((s) => s['_id']?.toString() == id).toList();
        if (matched.isNotEmpty) return matched.first['username']?.toString();
      }
    } else if (staffRef != null) {
      final id = staffRef.toString();
      if (id.isNotEmpty) {
        final matched = staffList.where((s) => s['_id']?.toString() == id).toList();
        if (matched.isNotEmpty) return matched.first['username']?.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewmodel>().user;
    final localRole = user?.role;

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
          final profile = (data['profile'] as Map?)?.cast<String, dynamic>() ?? {};
          final role = (profile['role']?.toString() ?? localRole ?? 'coach');
          final canManagePlayers = role != 'player';

          final teams = (data['teams'] as List? ?? [])
              .cast<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
          final staffList = (data['staff'] as List? ?? [])
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
          final coachName = _extractStaffName(team['coachStaffId'], staffList);
          final assistantCoachName = _extractStaffName(team['assistantCoachStaffId'], staffList);

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
                            canManagePlayers,
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
