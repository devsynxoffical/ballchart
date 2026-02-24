import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/courtiq_bottom_nav.dart';
import '../battle/view/battle_screen.dart';
import '../home/view/home_screen.dart';
import '../profile/view/profile_screen.dart';
import '../strategy/view/strategy_screen.dart';
import '../coach/home/view/coach_home_screen.dart';
import '../management/view/management_screen.dart';
import 'package:provider/provider.dart';
import '../profile/viewmodel/profile_viewmodel.dart';


class AppNavigator extends StatefulWidget {
  final String role;
  const AppNavigator({super.key, required this.role});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _currentIndex = 0;
  late List<Widget> _memoizedScreens;

  @override
  void initState() {
    super.initState();
    _memoizedScreens = _buildScreens();
    
    // Centralized profile load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewmodel>().loadProfile();
    });
  }

  List<Widget> _buildScreens() {
    final bool isHC = widget.role == 'head_coach';
    final List<Widget> screens = [
      (widget.role == 'coach' || widget.role == 'head_coach' || widget.role == 'assistant_coach')
          ? const CoachHomeScreen()
          : const HomeScreen(),
    ];

    if (isHC) {
      screens.add(const ManagementScreen());
    }

    screens.addAll([
      const BattleScreen(),
      const StrategyScreen(),
      const ProfileScreen(),
    ]);

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
        
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
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
        bottomNavigationBar: CourtIQBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          role: widget.role,
        ),
      ),
    );
  }
}