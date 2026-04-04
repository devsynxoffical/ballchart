import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class SelectableChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const SelectableChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.yellow.withOpacity(0.15) : Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: AppColors.yellow)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.yellow : Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
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
