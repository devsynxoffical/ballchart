import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:courtiq/core/repositories/dashboard_repository.dart';
import 'package:courtiq/features/profile/viewmodel/profile_viewmodel.dart';

class PlayerDashboardScreen extends StatelessWidget {
  const PlayerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        title: const Text('Player Dashboard'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: DashboardRepository().getPlayerDashboard(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final user = context.watch<ProfileViewmodel>().user;
          final team = (data['team'] as Map?)?.cast<String, dynamic>();
          final profile = (data['profile'] as Map?)?.cast<String, dynamic>() ?? {};
          final stats = (profile['stats'] as Map?)?.cast<String, dynamic>() ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? profile['username']?.toString() ?? 'Player',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _infoCard(
                  title: 'Profile',
                  children: [
                    _infoRow('Role', 'player'),
                    _infoRow('Position', profile['position']?.toString() ?? '-'),
                    _infoRow('Age Range', profile['ageRange']?.toString() ?? '-'),
                  ],
                ),
                const SizedBox(height: 12),
                _infoCard(
                  title: 'Team',
                  children: [
                    _infoRow('Team Name', team?['name']?.toString() ?? 'Unassigned'),
                    _infoRow('Age Group', team?['ageGroup']?.toString() ?? 'Open'),
                  ],
                ),
                const SizedBox(height: 12),
                _infoCard(
                  title: 'Stats',
                  children: [
                    _StaticInfoRow('Matches Played', '${stats['matchesPlayed'] ?? 0}'),
                    _StaticInfoRow('Wins', '${stats['wins'] ?? 0}'),
                    _StaticInfoRow('Points', '${stats['points'] ?? 0}'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$key: ', style: const TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StaticInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _StaticInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
