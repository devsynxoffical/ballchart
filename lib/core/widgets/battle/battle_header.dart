import 'package:flutter/material.dart';

class BattleHeader extends StatelessWidget {
  const BattleHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Training Battle',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Complete tasks to earn points and climb the ranks',
          style: TextStyle(color: Colors.white60),
        ),
      ],
    );
  }
}
