import 'package:flutter/material.dart';

import '../constants/colors.dart';

class HoopStarBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const HoopStarBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Define colors for each screen
  Color _getColorForIndex(int index) {
    switch (index) {
      case 0: // Home
        return AppColors.yellow; // Yellow/Amber
      case 1: // Battle
        return const Color(0xFF3B82F6); // Blue
      case 2: // Strategy
        return AppColors.yellow; // Yellow/Amber
      case 3: // Profile
        return const Color(0xFF8B5CF6); // Purple/Blue-Purple
      default:
        return AppColors.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home,
              label: 'Home',
              isActive: currentIndex == 0,
              activeColor: _getColorForIndex(0),
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.flash_on,
              label: 'Battle',
              isActive: currentIndex == 1,
              activeColor: _getColorForIndex(1),
              onTap: () => onTap(1),
            ),
            _NavItem(
              icon: Icons.analytics,
              label: 'Strategy',
              isActive: currentIndex == 2,
              activeColor: _getColorForIndex(2),
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: Icons.person,
              label: 'Profile',
              isActive: currentIndex == 3,
              activeColor: _getColorForIndex(3),
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isActive ? Colors.black : Colors.white54),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? activeColor : Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
