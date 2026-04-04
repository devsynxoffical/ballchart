import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class StrategyHeader extends StatelessWidget {
  const StrategyHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Strategy Board',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Game plans and tactical breakdowns',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
        const Spacer(),
        CircleAvatar(
          backgroundColor: AppColors.yellow,
          child: Icon(Icons.add, color: Colors.black),
        ),
      ],
    );
  }
}
