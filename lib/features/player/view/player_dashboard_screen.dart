import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:courtiq/features/management/viewmodel/academy_provider.dart';

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
      body: Consumer<AcademyProvider>(
        builder: (context, provider, _) {
          final user = provider.currentUser;
          final team = provider.playerTeam;
          final player = team?.players.firstWhere(
            (p) => p.name == (user?.name ?? ''),
            orElse: () => team.players.first,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Player',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _infoCard(
                  title: 'Profile',
                  children: [
                    _infoRow('Role', 'player'),
                    _infoRow('Position', player?.position ?? 'Point Guard'),
                    _infoRow('Age', '${player?.age ?? 18}'),
                  ],
                ),
                const SizedBox(height: 12),
                _infoCard(
                  title: 'Team',
                  children: [
                    _infoRow('Team Name', team?.name ?? 'Under 18'),
                  ],
                ),
                const SizedBox(height: 12),
                _infoCard(
                  title: 'Stats (Dummy)',
                  children: const [
                    _StaticInfoRow('Matches Played', '24'),
                    _StaticInfoRow('Wins', '18'),
                    _StaticInfoRow('Points', '485'),
                  ],
                ),
                const SizedBox(height: 12),
                _infoCard(
                  title: 'Battle History (Dummy)',
                  children: const [
                    _StaticInfoRow('vs Rising Stars', 'Win 82-74'),
                    _StaticInfoRow('vs City Hawks', 'Loss 68-71'),
                    _StaticInfoRow('vs Thunder Squad', 'Win 90-88'),
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
