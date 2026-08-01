import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/core/services/api_service.dart';
import 'package:ballchart/core/widgets/inbox_header_icons.dart';
import 'package:ballchart/features/inbox/viewmodel/inbox_viewmodel.dart';
import '../../../profile/viewmodel/profile_viewmodel.dart';
import '../../../battle/view/battle_screen.dart';
import '../../../strategy/view/enhanced_strategy_screen.dart';
import '../../../profile/view/profile_screen.dart';
import 'widgets/teams_tab.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => CoachHomeScreenState();
}

class CoachHomeScreenState extends State<CoachHomeScreen> {
  int _currentTab = 0;

  // BallChart Redesign Tokens - Same as Admin Panel
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color outlineColor = Color(0xFF9D8F79);

  /// Used by [AppNavigator] for a single shared exit flow.
  /// Returns true if this screen consumed the back (switched to home tab).
  bool handleSystemBack() {
    if (_currentTab != 0) {
      setState(() => _currentTab = 0);
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InboxViewModel>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ProfileViewmodel>();

    // Exit popup is owned by AppNavigator so coach / player / admin all share
    // one consistent back → exit flow.
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: _buildEnhancedHeader(),
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          const TeamsTab(),
          BattleScreen(),
          EnhancedStrategyScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildEnhancedHeader() {
    final user = context.watch<ProfileViewmodel>().user;
    final name = user?.username ?? 'Coach';
    final role = user?.role ?? 'coach';
    final academyName = (user?.academyName ?? user?.teamName)?.trim() ?? '';
    final displayName = name.trim().isEmpty ? 'Coach' : name.split(' ').first;
    final picRaw = user?.profileImageUrl;
    final picUrl = (picRaw != null && picRaw.trim().isNotEmpty)
        ? ApiService.resolveMediaUrl(picRaw)
        : '';
    final hasPhoto = picUrl.isNotEmpty &&
        (picUrl.startsWith('http://') || picUrl.startsWith('https://'));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (hasPhoto) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withValues(alpha: 0.55), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                picUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Space Grotesk',
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        role.toUpperCase().replaceAll('_', ' '),
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (academyName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          academyName,
                          style: const TextStyle(
                            color: outlineColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const MessagesIconButton(),
          const NotificationBellButton(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainer,
        border: Border(top: BorderSide(color: outlineColor.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'HOME'),
              _buildNavItem(1, Icons.sports_basketball_outlined, Icons.sports_basketball, 'GAMES'),
              _buildNavItem(2, Icons.psychology_outlined, Icons.psychology, 'STRATEGY'),
              _buildNavItem(3, Icons.person_outline, Icons.person, 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentTab == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? primaryColor : outlineColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? primaryColor : outlineColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
