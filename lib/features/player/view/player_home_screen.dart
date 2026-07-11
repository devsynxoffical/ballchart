import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/core/models/user_model.dart';
import 'package:ballchart/core/services/api_service.dart';
import 'package:ballchart/core/widgets/inbox_header_icons.dart';
import 'package:ballchart/features/inbox/viewmodel/inbox_viewmodel.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../../battle/view/battle_screen.dart';
import '../../strategy/view/strategy_screen.dart';
import '../../profile/view/profile_screen.dart';
import '../widgets/player_stats_tab.dart';

class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  int _currentTab = 0;
  final GlobalKey<PlayerStatsTabState> _playerStatsTabKey = GlobalKey<PlayerStatsTabState>();

  // BallChart Redesign Tokens - Same as Admin Panel
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InboxViewModel>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentTab != 0) {
          setState(() => _currentTab = 0);
          return;
        }
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        toolbarHeight: 88,
        titleSpacing: 16,
        title: _buildEnhancedHeader(),
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          PlayerStatsTab(key: _playerStatsTabKey),
          const BattleScreen(),
          const StrategyScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceContainer,
        title: const Text('Exit App', style: TextStyle(color: Colors.white)),
        content: const Text('Do you want to exit the application?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No', style: TextStyle(color: Colors.white60))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes', style: TextStyle(color: primaryColor))),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    final user = context.watch<ProfileViewmodel>().user;
    final name = user?.username ?? 'Player';
    final role = user?.role ?? 'player';
    final academyName = (user?.academyName ?? user?.teamName)?.trim() ?? '';
    final displayName = name.trim().isEmpty ? 'Player' : name.split(' ').first;
    final picRaw = user is UserModel ? user.profileImageUrl : null;
    final picUrl = (picRaw != null && picRaw.trim().isNotEmpty) ? ApiService.resolveMediaUrl(picRaw) : '';
    final hasPhoto = picUrl.isNotEmpty && (picUrl.startsWith('http://') || picUrl.startsWith('https://'));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    picUrl,
                    fit: BoxFit.cover,
                    width: 48,
                    height: 48,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                        style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
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
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        role.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (academyName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• $academyName',
                        style: const TextStyle(
                          color: outlineColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
          // Status Indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
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
      onTap: () {
        setState(() => _currentTab = index);
        if (index == 0) {
          _playerStatsTabKey.currentState?.refreshTrainingSummary();
        }
      },
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
