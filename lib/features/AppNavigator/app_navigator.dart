import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../battle/view/battle_screen.dart';
import '../home/view/home_screen.dart';
import '../profile/view/profile_screen.dart';
import '../strategy/view/enhanced_strategy_screen.dart';
import '../coach/home/view/coach_home_screen.dart';
import '../player/view/player_home_screen.dart';
import '../management/view/management_screen.dart';
import 'package:provider/provider.dart';
import '../profile/viewmodel/profile_viewmodel.dart';
import '../management/viewmodel/academy_provider.dart';
import '../inbox/viewmodel/inbox_viewmodel.dart';


class AppNavigator extends StatefulWidget {
  final String role;
  const AppNavigator({super.key, required this.role});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _currentIndex = 0;
  String _effectiveRole = '';
  late List<Widget> _memoizedScreens;

  @override
  void initState() {
    super.initState();
    _effectiveRole = widget.role;
    _memoizedScreens = _buildScreens();
    
    // Centralized profile load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InboxViewModel>().start();
      final profileVm = context.read<ProfileViewmodel>();
      profileVm.loadProfile(forceRefresh: true).then((_) {
        final u = profileVm.user;
        if (!mounted) return;
        if (u != null) {
          final academy = context.read<AcademyProvider>();
          academy.setCurrentUser(u);
          final role = (u.role).toLowerCase();
          if (role == 'coach' || role == 'assistant_coach' || role == 'head_coach') {
            unawaited(academy.loadCoachDashboard(force: true));
          } else if (role == 'player') {
            unawaited(academy.loadPlayerDashboard(force: true));
          } else if (role == 'admin') {
            unawaited(academy.loadAdminOverview(force: true));
          }
        }
        final resolvedRole = u?.role;
        if (resolvedRole == null || resolvedRole.isEmpty) return;
        if (resolvedRole != _effectiveRole) {
          setState(() {
            _effectiveRole = resolvedRole;
            _currentIndex = 0;
            _memoizedScreens = _buildScreens();
          });
        }
      });
    });
  }

  List<Widget> _buildScreens() {
    final role = _effectiveRole;
    final bool isHC = role == 'head_coach';
    final List<Widget> screens = [
      if (role == 'coach' || role == 'head_coach' || role == 'assistant_coach')
        const CoachHomeScreen()
      else if (role == 'player')
        const PlayerHomeScreen()
      else
        const HomeScreen(),
    ];

    if (isHC) {
      screens.add(const ManagementScreen());
    }

    return screens;
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Exit App', style: TextStyle(color: Colors.white)),
        content: const Text('Do you want to exit the application?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        // If not on first tab, navigate to first tab (home)
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          // If on first tab, show exit dialog
          final shouldExit = await _showExitDialog(context);
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _memoizedScreens,
        ),
      ),
    );
  }
}