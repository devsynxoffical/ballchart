import 'package:flutter/material.dart';

import '../../constants/colors.dart';

import '../../models/user_model.dart';

class RankProgressCard extends StatelessWidget {
  final UserModel user;
  const RankProgressCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final points = user.stats['points'] as int? ?? 0;
    
    // Simple logic: Each rank is 1000 points.
    final currentRankLevel = (points / 1000).floor() + 1;
    final nextRankPoints = currentRankLevel * 1000;
    final pointsToNext = nextRankPoints - points;
    final progress = (points % 1000) / 1000;
    
    final rankName = _getRankName(currentRankLevel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.pinkAccent,
            child: const Icon(Icons.star, color: AppColors.yellow),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rankName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rank #${user.rank > 0 ? user.rank : currentRankLevel}', 
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: Colors.purpleAccent,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$pointsToNext more points to next level! 🏆',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$points pts',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRankName(int level) {
    if (level == 1) return 'Rookie';
    if (level == 2) return 'Semi-Pro';
    if (level == 3) return 'Pro';
    if (level == 4) return 'All-Star';
    if (level == 5) return 'Superstar';
    return 'Legend';
  }
}
