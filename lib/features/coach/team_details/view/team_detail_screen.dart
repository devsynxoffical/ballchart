import 'package:flutter/material.dart';
import 'widgets/hierarchy_management_widget.dart';
import 'package:provider/provider.dart';
import '../../../profile/viewmodel/profile_viewmodel.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamName;

  const TeamDetailScreen({super.key, required this.teamName});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  // Mock Roster Data
  final List<Map<String, String>> _players = [
    {'name': 'John Doe', 'position': 'Point Guard', 'number': '#4'},
    {'name': 'Mike Smith', 'position': 'Center', 'number': '#12'},
    {'name': 'Sarah Cone', 'position': 'Shooting Guard', 'number': '#7'},
  ];

  void _addPlayer(Map<String, String> player) {
    setState(() {
      _players.add(player);
    });
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewmodel>().user;
    final role = user?.role ?? 'player';
    final canRemove = role == 'coach' || role == 'head_coach';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Hierarchy Management Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: HierarchyManagementWidget(
                onPlayerAdded: _addPlayer,
                role: role,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Stats / Roster Placeholder
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
                  ..._players.asMap().entries.map((entry) {
                    final index = entry.key;
                    final p = entry.value;
                    return _buildRosterItem(
                      p['name']!, 
                      p['position']!, 
                      p['number']!.startsWith('#') ? p['number']! : '#${p['number']}',
                      canRemove,
                      () => _removePlayer(index),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
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
            const Icon(Icons.lock_outline, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}
