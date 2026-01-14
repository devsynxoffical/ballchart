import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class SelectableTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const SelectableTile({
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
          color: selected ? AppColors.yellow.withOpacity(0.15) : Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: AppColors.yellow)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected ? AppColors.yellow : Colors.white54,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.yellow : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
