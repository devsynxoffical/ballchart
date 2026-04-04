import 'package:flutter/material.dart';

import '../custom_button.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String duration;
  final String difficulty;
  final String points;
  final Color difficultyColor;

  const TaskCard({
    required this.title,
    required this.duration,
    required this.difficulty,
    required this.points,
    required this.difficultyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white10,
                child: Icon(Icons.flash_on, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          duration,
                          style: const TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          difficulty,
                          style: TextStyle(
                            color: difficultyColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: 'Mark as Done   $points',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
