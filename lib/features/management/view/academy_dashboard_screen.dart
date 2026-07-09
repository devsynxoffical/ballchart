import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/core/constants/colors.dart';
import 'package:ballchart/core/widgets/dialogues/CreateTeamDialog.dart';
import 'package:ballchart/core/widgets/dialogues/CreateStaffDialog.dart';
import 'package:ballchart/core/widgets/inbox_header_icons.dart';
import 'package:ballchart/core/widgets/permission_wrapper.dart';
import 'package:ballchart/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:ballchart/features/inbox/viewmodel/inbox_viewmodel.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';
import 'package:ballchart/features/staff/view/staff_list_screen.dart';
import 'package:ballchart/features/profile/view/profile_screen.dart';
import 'package:ballchart/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:ballchart/features/player/view/player_detail_screen.dart';
import 'package:ballchart/features/coach/team_details/view/team_detail_screen.dart';

String _teamDivisionLabel(String ageGroup) {
  final raw = ageGroup.trim().toUpperCase().replaceAll('U-', 'U').replaceAll(' ', '');
  if (raw.isEmpty || raw == 'OPEN') return 'Open Division';
  return '$raw Division';
}

class AcademyDashboardScreen extends StatefulWidget {
  const AcademyDashboardScreen({super.key});

  @override
  State<AcademyDashboardScreen> createState() => _AcademyDashboardScreenState();
}

class _AcademyDashboardScreenState extends State<AcademyDashboardScreen> {
  int _currentTab = 0;
  AcademyProvider? _academyProvider;

  // BallChart Redesign Tokens
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
      _syncAcademyUserFromProfile();
      if (mounted) context.read<InboxViewModel>().start();
      // Load data with error handling
      _loadDataWithRetry();
      
      // Listen to provider changes for error/success messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _academyProvider = context.read<AcademyProvider>();
        _academyProvider!.addListener(_onProviderChanged);
      });
    });
  }

  /// Session restore (e.g. via Splash) can leave [AcademyProvider.currentUser] null; permissions stay false.
  void _syncAcademyUserFromProfile() {
    if (!mounted) return;
    final profileUser = context.read<ProfileViewmodel>().user;
    final academy = context.read<AcademyProvider>();
    if (profileUser != null && academy.currentUser == null) {
      academy.setCurrentUser(profileUser);
    }
  }

  void _onProviderChanged() {
    if (!mounted) return;
    
    final provider = context.read<AcademyProvider>();
    
    // Show error message if exists
    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearError();
      });
    }
    
    // Show success message if exists
    if (provider.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.successMessage!),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      // Clear the success message after showing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearSuccessMessage();
      });
    }
  }

  @override
  void dispose() {
    _academyProvider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        await context.read<AcademyProvider>().loadAdminOverview();
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load academy data: ${e.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _loadDataWithRetry(),
                ),
              ),
            );
          }
        } else {
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildTopAppBar(),
        body: Consumer<AcademyProvider>(
          builder: (context, provider, _) {
            final body = _buildBody(provider);
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey<int>(_currentTab),
                child: body,
              ),
            );
          },
        ),
        bottomNavigationBar: _buildModernBottomNav(),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_currentTab != 0) {
      if (mounted) setState(() => _currentTab = 0);
      return false;
    }
    final shouldExit = await _showExitDialog(context);
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
    return false;
  }

  Future<void> _handleBackNavigation() async {
    await _onWillPop();
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceContainer,
        title: const Text('Exit App', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Do you want to exit the application?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    final academyName = context.watch<AcademyProvider>().academy.name.trim();
    final titleText = academyName.isEmpty ? 'ACADEMY' : academyName.toUpperCase();
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        titleText,
        style: const TextStyle(
          color: primaryColor,
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
          fontSize: 18,
        ),
      ),
      actions: [
        const MessagesIconButton(iconColor: Colors.white),
        const NotificationBellButton(iconColor: Colors.white),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(AcademyProvider provider) {
    // Only block the whole screen until the first admin overview succeeds. Mutations (create team,
    // staff, etc.) and refreshes still set [isLoading] but must not hide Tactical Actions.
    if (provider.isLoading && !provider.hasLoadedAdminOverview) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text('Loading Academy Data...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadDataWithRetry(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    switch (_currentTab) {
      case 0: return _buildDashboard(provider);
      case 1: return _buildTeamsSection(provider);
      case 2: return _buildStaffSection(provider);
      case 3: return _buildProfileSection(provider);
      default: return _buildDashboard(provider);
    }
  }

  Widget _buildDashboard(AcademyProvider provider) {
    final totalPlayers = provider.academy.teams.fold<int>(0, (sum, team) => sum + team.players.length);

    return RefreshIndicator(
      onRefresh: () => provider.loadAdminOverview(force: true),
      color: primaryColor,
      backgroundColor: surfaceHigh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Academy Hero / Stats Bento
          _buildHeroBento(provider.academy.teams.length, provider.academy.staff.length, totalPlayers),
          const SizedBox(height: 24),
          _buildTopPerformerCard(provider),
          const SizedBox(height: 12),
          
          // Performance Mini Cards
          Row(
            children: [
              Expanded(child: _buildMiniStat('${(totalPlayers > 0 ? 92 : 0)}%', 'Activity Rate', Icons.trending_up, const Color(0xFF28D8FF))),
              const SizedBox(width: 12),
              Expanded(child: _buildMiniStat('Level ${provider.academy.teams.length}', 'Squad Maturity', Icons.verified_user, primaryColor)),
            ],
          ),
          const SizedBox(height: 32),
  
          // Tactical Actions
          const Text(
            'TACTICAL ACTIONS',
            style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PermissionWrapper(
                  permission: 'createTeam',
                  child: _buildActionButton(
                    'Add Team', 
                    Icons.group_add_rounded, 
                    primaryColor, 
                    Colors.black,
                    () => _showCreateTeamDialog(context)
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PermissionWrapper(
                  permission: 'manageStaff',
                  child: _buildActionButton(
                    'Invite Staff', 
                    Icons.person_add_rounded, 
                    surfaceHigh, 
                    Colors.white,
                    () => _showInviteStaffDialog(context)
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
  
          // Active Squads Carousel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE SQUADS',
                style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              TextButton(
                onPressed: () => setState(() => _currentTab = 1),
                child: const Text('VIEW ALL', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSquadCarousel(provider.academy.teams),
          const SizedBox(height: 32),
  
          // Top Performer
          const Text(
            'TOP PERFORMER',
            style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          _buildTopPerformerCard(provider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroBento(int teams, int staff, int players) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACADEMY OVERVIEW',
            style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          const Text(
            'BALLCHART COMMAND',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Space Grotesk',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bentoStat('$teams', 'Total Teams'),
              _bentoStat('$staff', 'Staff Members'),
              _bentoStat('$players', 'Active Players'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bentoStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
        Text(label.toUpperCase(), style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color iconColor) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
              Text(label.toUpperCase(), style: const TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color bg, Color text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: bg == primaryColor ? [
            BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: text, size: 20),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadCarousel(List<Team> teams) {
    if (teams.isEmpty) return const SizedBox(height: 180, child: Center(child: Text('No active squads', style: TextStyle(color: outlineColor))));
    
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamDetailScreen(teamId: team.id, teamName: team.name),
                ),
              );
            },
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: surfaceHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/header.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [surfaceHigh, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(team.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.groups_rounded, color: outlineColor, size: 14),
                                const SizedBox(width: 4),
                                Text('${team.players.length} PLAYERS', style: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                const Icon(Icons.stadium_rounded, color: outlineColor, size: 14),
                                const SizedBox(width: 4),
                                const Text('COURT 1', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: 0.75,
                              backgroundColor: bgColor,
                              valueColor: const AlwaysStoppedAnimation(primaryColor),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 100,
                    right: 16,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        team.ageGroup.substring(0, 3).toUpperCase(),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopPerformerCard(AcademyProvider provider) {
    if (provider.academy.teams.isEmpty || provider.academy.teams.first.players.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: surfaceHighest, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text('NO PERFORMANCE DATA YET', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold))),
      );
    }

    final topPlayer = provider.academy.teams.first.players.first;
    final teamName = provider.academy.teams.first.name;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailScreen(player: topPlayer),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: surfaceHigh,
              child: Text(
                topPlayer.name.trim().isNotEmpty ? topPlayer.name.trim()[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topPlayer.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${topPlayer.position.toUpperCase()} • $teamName', style: const TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _perfStat('LATEST', 'STATS'),
                      const SizedBox(width: 16),
                      _perfStat('SYNCED', 'LIVE'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star_rounded, color: primaryColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perfStat(String value, String label) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const TextSpan(text: ' '),
          TextSpan(text: label, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B1B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _newNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
          _newNavItem(1, Icons.groups_rounded, 'Teams'),
          _newNavItem(2, Icons.badge_rounded, 'Staff'),
          _newNavItem(3, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _newNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_currentTab != index) {
            setState(() => _currentTab = index);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isSelected ? BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.15), primaryColor.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
          ) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? primaryColor : outlineColor, size: 22),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? primaryColor : outlineColor,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surfaceHigh,
        title: const Text('Log out', style: TextStyle(color: Colors.white)),
        content: const Text('Do you want to log out of admin dashboard?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      await context.read<AuthViewmodel>().logout(context);
    }
  }

  void _showCreateTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CreateTeamDialog(
        onTeamCreated: (name, age, color, logoPath, coachId, assistantId) async {
          final provider = context.read<AcademyProvider>();
          try {
            await provider.addTeamToBackend(
              Team(
                id: provider.nextId('t'),
                name: name,
                players: const [],
                ageGroup: age,
                colorValue: color.value,
                logoPath: logoPath,
                coachStaffId: coachId,
                assistantCoachStaffId: assistantId,
              ),
            );
            if (context.mounted) Navigator.pop(context);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('SQUAD $name INITIALIZED')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('FAILED: $e'), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
      ),
    );
  }

  void _showInviteStaffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateStaffDialog(
        initialRole: 'Coach',
        onStaffCreated: (staffData) async {
          final provider = context.read<AcademyProvider>();
          try {
            await provider.addStaffToBackend(
              Staff(
                id: provider.nextId('s'),
                name: staffData['name'] ?? '',
                email: staffData['email'] ?? '',
                password: staffData['password'] ?? '',
                role: (staffData['role'] ?? 'coach').toString().toLowerCase().replaceAll(' ', '_'),
                customRoleName: staffData['customRoleName']?.toString(),
                assignedTeamIds: const [],
                permissions: Permissions.fromDynamic(staffData['permissions']),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  Widget _buildTeamsSection(AcademyProvider provider) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        const Text('ALL TEAMS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
        const SizedBox(height: 4),
        const Text('ACADEMY SQUAD DIRECTORY', style: TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 32),
        ...provider.academy.teams.map((team) => GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeamDetailScreen(teamId: team.id, teamName: team.name),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(width: 4, height: 24, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 20, 
                  backgroundColor: surfaceContainer,
                  child: Text(team.name.isNotEmpty ? team.name[0] : 'T', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Space Grotesk')),
                      Text('${_teamDivisionLabel(team.ageGroup)} • ${team.players.length} PLAYERS', style: const TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: outlineColor, size: 14),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildStaffSection(AcademyProvider provider) => const StaffListScreen();
  Widget _buildStatsSection(AcademyProvider provider) => _buildDashboard(provider);
  Widget _buildProfileSection(AcademyProvider provider) => const ProfileScreen();
}
