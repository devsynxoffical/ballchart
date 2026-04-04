import 'package:flutter/material.dart';

import '../../constants/colors.dart';


class StrategyTabs extends StatelessWidget {
  const StrategyTabs();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _TabChip(label: 'All Strategies', isActive: true),
          _TabChip(label: 'Offense'),
          _TabChip(label: 'Defense'),
          _TabChip(label: 'Drills'),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TabChip({
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.yellow : Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white60,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
