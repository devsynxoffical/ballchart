import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/profile/viewmodel/profile_viewmodel.dart';
import '../../constants/colors.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  String _getRoleLabel(String role) {
    switch (role) {
      case 'head_coach':
        return 'Academy Owner';
      case 'assistant_coach':
        return 'Assistant Coach';
      case 'coach':
        return 'Coach';
      default:
        return 'Coach';
    }
  }

  Color _getRoleBadgeColor(String role) {
    switch (role) {
      case 'head_coach':
        return AppColors.yellow;
      case 'assistant_coach':
        return const Color(0xFF8B5CF6);
      case 'coach':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewmodel>().user;
    final name = user?.username ?? 'Coach';
    final role = user?.role ?? 'coach';
    final academyName = user?.teamName?.trim();
    final displayName = role == 'head_coach' && academyName != null && academyName.isNotEmpty
        ? academyName
        : name.split(' ').first;
    final roleLabel = _getRoleLabel(role);
    final badgeColor = _getRoleBadgeColor(role);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [badgeColor, badgeColor.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hey, $displayName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(Icons.notifications_outlined, color: Colors.white70, size: 22),
              ),
              Positioned(
                top: 8,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF020617), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
