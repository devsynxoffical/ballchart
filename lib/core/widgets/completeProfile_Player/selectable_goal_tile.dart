import 'package:flutter/material.dart';

class SelectableGoalTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const SelectableGoalTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(0.15) : Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.blue : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? Colors.blue : Colors.white54,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.blue : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
