import 'package:flutter/material.dart';

import '../constants/colors.dart';

class CourtIQBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role;

  const CourtIQBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  // Define colors based on role and tab index
  Color _getColorForIndex(int index) {
    if (role == 'head_coach') {
      switch (index) {
        case 0: return AppColors.yellow; // Home
        case 1: return Colors.blueAccent; // Manage
        case 2: return const Color(0xFF3B82F6); // Battle
        case 3: return AppColors.yellow; // Strategy
        case 4: return const Color(0xFF8B5CF6); // Profile
        default: return AppColors.yellow;
      }
    } else {
      switch (index) {
        case 0: return AppColors.yellow; 
        case 1: return const Color(0xFF3B82F6);
        case 2: return AppColors.yellow; 
        case 3: return const Color(0xFF8B5CF6);
        default: return AppColors.yellow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isHC = role == 'head_coach';

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
            if (isHC)
              _NavItem(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Manage',
                isActive: currentIndex == 1,
                activeColor: _getColorForIndex(1),
                onTap: () => onTap(1),
              ),
            _NavItem(
              icon: Icons.flash_on,
              label: 'Battle',
              isActive: isHC ? currentIndex == 2 : currentIndex == 1,
              activeColor: isHC ? _getColorForIndex(2) : _getColorForIndex(1),
              onTap: () => onTap(isHC ? 2 : 1),
            ),
            _NavItem(
              icon: Icons.analytics,
              label: 'Strategy',
              isActive: isHC ? currentIndex == 3 : currentIndex == 2,
              activeColor: isHC ? _getColorForIndex(3) : _getColorForIndex(2),
              onTap: () => onTap(isHC ? 3 : 2),
            ),
            _NavItem(
              icon: Icons.person,
              label: 'Profile',
              isActive: isHC ? currentIndex == 4 : currentIndex == 3,
              activeColor: isHC ? _getColorForIndex(4) : _getColorForIndex(3),
              onTap: () => onTap(isHC ? 4 : 3),
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
