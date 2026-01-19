import 'package:flutter/material.dart';

import '../../core/widgets/hoopstar_bottom_nav.dart';
import '../battle/view/battle_screen.dart';
import '../home/view/home_screen.dart';
import '../profile/view/profile_screen.dart';
import '../strategy/view/strategy_screen.dart';
import '../coach/home/view/coach_home_screen.dart';


class AppNavigator extends StatefulWidget {
  final String role;
  const AppNavigator({super.key, required this.role});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    widget.role == 'coach' ? const CoachHomeScreen() : const HomeScreen(),
    const BattleScreen(),
    const StrategyScreen(),
    const ProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: HoopStarBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}