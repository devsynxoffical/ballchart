import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/core/widgets/app_exit_scope.dart';

import '../home/view/home_screen.dart';
import '../coach/home/view/coach_home_screen.dart';
import '../player/view/player_home_screen.dart';
import '../management/view/management_screen.dart';
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

  final GlobalKey<CoachHomeScreenState> _coachHomeKey =
      GlobalKey<CoachHomeScreenState>();
  final GlobalKey<PlayerHomeScreenState> _playerHomeKey =
      GlobalKey<PlayerHomeScreenState>();

  @override
  void initState() {
    super.initState();
    _effectiveRole = widget.role;
    _memoizedScreens = _buildScreens();

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
    final role = _effectiveRole.toLowerCase();
    final bool isHC = role == 'head_coach';
    final List<Widget> screens = [
      if (role == 'coach' || role == 'head_coach' || role == 'assistant_coach')
        CoachHomeScreen(key: _coachHomeKey)
      else if (role == 'player')
        PlayerHomeScreen(key: _playerHomeKey)
      else
        const HomeScreen(),
    ];

    if (isHC) {
      screens.add(const ManagementScreen());
    }

    return screens;
  }

  /// Returns true when back was consumed (tab switch), false to show exit dialog.
  Future<bool> _handleRootBack() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return true;
    }

    final coachHandled = _coachHomeKey.currentState?.handleSystemBack() ?? false;
    if (coachHandled) return true;

    final playerHandled = _playerHomeKey.currentState?.handleSystemBack() ?? false;
    if (playerHandled) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // One exit guard for every coach / player / head-coach shell.
    return AppExitScope(
      onBack: _handleRootBack,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _memoizedScreens,
        ),
      ),
    );
  }
}
