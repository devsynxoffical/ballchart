import 'package:flutter/material.dart';
class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'My Teams',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage your basketball squads',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
        const Spacer(),
        CircleAvatar(
          backgroundColor: Colors.white10,
          child: Icon(Icons.notifications, color: Colors.amber),
        ),
      ],
    );
  }
}
