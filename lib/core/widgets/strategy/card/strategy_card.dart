import 'package:flutter/material.dart';
import 'package:hoopstar/core/widgets/strategy/card/voice_explanation.dart';

import 'card_footer.dart';
import 'coach_Info.dart';
import 'media_preview.dart';

enum StrategyMedia { image, video }

class StrategyCard extends StatelessWidget {
  final String coachName;
  final String role;
  final String timeAgo;
  final String title;
  final StrategyMedia imageType;
  final String mediaDuration;
  final int likes;
  final int comments;

  const StrategyCard({
    required this.coachName,
    required this.role,
    required this.timeAgo,
    required this.title,
    required this.imageType,
    required this.mediaDuration,
    required this.likes,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoachInfo(coachName, role, timeAgo),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          MediaPreview(imageType),
          VoiceExplanation(mediaDuration),
          CardFooter(likes, comments),
        ],
      ),
    );
  }
}
