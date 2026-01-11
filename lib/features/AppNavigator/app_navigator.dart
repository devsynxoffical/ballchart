import 'package:flutter/material.dart';

import '../../core/widgets/hoopstar_bottom_nav.dart';
import '../battle/view/battle_screen.dart';
import '../home/view/home_screen.dart';
import '../profile/view/profile_screen.dart';
import '../strategy/view/strategy_screen.dart';


class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BattleScreen(),
    StrategyScreen(),
    ProfileScreen(),
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