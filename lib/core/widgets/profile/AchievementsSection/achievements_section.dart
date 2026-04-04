import 'package:flutter/material.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Achievements',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            const _Achievement(icon: Icons.emoji_events, label: 'First Win'),
            const _Achievement(icon: Icons.local_fire_department, label: '10 Day Streak'),
            const _Achievement(icon: Icons.flash_on, label: 'Speed Demon'),
            const _Achievement(icon: Icons.track_changes, label: 'Sharp Shooter', locked: true),
            _Achievement(icon: Icons.crop, label: 'MVP', locked: true),
            const _Achievement(icon: Icons.fitness_center, label: 'Iron Will', locked: true),
          ],
        ),
      ],
    );
  }
}

class _Achievement extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool locked;

  const _Achievement({
    required this.icon,
    required this.label,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 28,
              color: locked ? Colors.white24 : Colors.amber),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: locked ? Colors.white24 : Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
