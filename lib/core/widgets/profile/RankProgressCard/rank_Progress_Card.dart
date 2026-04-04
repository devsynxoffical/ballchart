import 'package:flutter/material.dart';

class RankProgressCard extends StatelessWidget {
  const RankProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF020617)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All-Star',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep pushing to reach Captain!',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: 375 / 485,
            backgroundColor: Colors.white24,
            valueColor:
            const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
          ),
          const SizedBox(height: 6),
          const Text(
            '375 / 485 pts',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
