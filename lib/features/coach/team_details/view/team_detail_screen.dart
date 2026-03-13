import 'package:flutter/material.dart';
import 'widgets/hierarchy_management_widget.dart';
import 'package:provider/provider.dart';
import '../../../profile/viewmodel/profile_viewmodel.dart';
import '../../../../core/repositories/dashboard_repository.dart';
import '../../../staff/service/staff_service.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamName;

  const TeamDetailScreen({super.key, required this.teamName});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final DashboardRepository _dashboardRepository = DashboardRepository();
  final StaffService _staffService = StaffService();

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
          final canManagePlayers = role == 'admin' || role == 'head_coach' || role == 'coach';

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
          final teamId = team['_id']?.toString() ?? '';
          final coachName = _extractStaffName(team['coachStaffId'], staffList);
          final assistantCoachName = _extractStaffName(team['assistantCoachStaffId'], staffList);

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: HierarchyManagementWidget(
                    onPlayerAdded: (_) {
                      if (mounted) setState(() {});
                    },
                    role: role,
                    teamId: teamId,
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
                            p['_id']?.toString() ?? '',
                            p['username']?.toString() ?? 'Player',
                            p['position']?.toString() ?? '-',
                            '#',
                            canManagePlayers,
                            () => _deletePlayer(p['_id']?.toString() ?? ''),
                            () => _editPlayerDialog(
                              p['_id']?.toString() ?? '',
                              p['username']?.toString() ?? '',
                              p['position']?.toString() ?? '',
                              p['ageRange']?.toString() ?? '',
                            ),
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

  Future<void> _deletePlayer(String playerId) async {
    if (playerId.isEmpty) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Delete Player', style: TextStyle(color: Colors.white)),
            content: const Text('Are you sure you want to delete this player?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    try {
      await _staffService.deletePlayer(playerId);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _editPlayerDialog(
    String playerId,
    String currentName,
    String currentPosition,
    String currentAgeRange,
  ) async {
    if (playerId.isEmpty) return;
    final nameController = TextEditingController(text: currentName);
    final positionController = TextEditingController(text: currentPosition);
    final ageRangeController = TextEditingController(text: currentAgeRange);

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Edit Player', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: positionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Position', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ageRangeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Age Range', labelStyle: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true) return;

    try {
      await _staffService.updatePlayer(
        playerId: playerId,
        name: nameController.text.trim(),
        position: positionController.text.trim(),
        ageRange: ageRangeController.text.trim(),
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildRosterItem(
    String playerId,
    String name,
    String position,
    String number,
    bool canRemove,
    VoidCallback onRemove,
    VoidCallback onEdit,
  ) {
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: onRemove,
                ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
