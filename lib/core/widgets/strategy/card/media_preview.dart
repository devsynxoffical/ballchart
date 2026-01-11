import 'package:flutter/material.dart';
import 'package:hoopstar/core/widgets/strategy/card/strategy_card.dart';

class MediaPreview extends StatelessWidget {
  final StrategyMedia type;

  const MediaPreview(this.type);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: type == StrategyMedia.video
            ? const Icon(Icons.play_circle_fill,
            size: 60, color: Colors.red)
            : const Icon(Icons.sports_basketball,
            size: 50, color: Colors.orange),
      ),
    );
  }
}
