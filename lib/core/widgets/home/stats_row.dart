import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class StatsRow extends StatelessWidget {
  final UserModel user;
  const StatsRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final stats = user.stats;
    return Row(
      children: [
        Expanded(child: _StatCard(value: stats['matchesPlayed'].toString(), label: 'Matches', color: Colors.amber)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: stats['wins'].toString(), label: 'Wins', color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: stats['points'].toString(), label: 'Points', color: Colors.green)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
