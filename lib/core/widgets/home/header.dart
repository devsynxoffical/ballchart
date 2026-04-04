import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/profile/viewmodel/profile_viewmodel.dart';
import '../../constants/colors.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Academy Owner';
      case 'head_coach':
        return 'Academy Owner';
      case 'assistant_coach':
        return 'Assistant Coach';
      case 'coach':
        return 'Coach';
      case 'player':
        return 'Player';
      default:
        return 'User';
    }
  }

  Color _getRoleBadgeColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.yellow;
      case 'head_coach':
        return AppColors.yellow;
      case 'assistant_coach':
        return const Color(0xFF8B5CF6);
      case 'coach':
        return const Color(0xFF3B82F6);
      case 'player':
        return const Color(0xFF10B981);
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewmodel>().user;
    final name = user?.username ?? 'User';
    final role = user?.role ?? 'coach';
    final academyName = user?.teamName?.trim() ?? '';
    final displayName = name.trim().isEmpty ? 'User' : name.split(' ').first;
    final roleLabel = _getRoleLabel(role);
    final badgeColor = _getRoleBadgeColor(role);
    final subtitle = academyName.isNotEmpty
        ? '$roleLabel • $academyName'
        : roleLabel;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [badgeColor, badgeColor.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child:
              Text(
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
                  'Welcome, $displayName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
            ),
            child:
              Text(
                roleLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
          ),
        ],
      ),
    );
  }
}
