import 'package:flutter/material.dart';

class TasksHeader extends StatelessWidget {
  const TasksHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Text(
          "Today's Tasks",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Spacer(),
        Text(
          '0/5 completed',
          style: TextStyle(color: Colors.white60),
        ),
      ],
    );
  }
}
