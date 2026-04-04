import 'package:flutter/material.dart';
import 'package:ballchart/core/widgets/dialogues/CreateTeamDialog.dart';
import 'package:ballchart/features/coach/team_details/view/team_detail_screen.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import '../../../../management/viewmodel/academy_provider.dart';
import 'package:provider/provider.dart';

class TeamsTab extends StatefulWidget {
  const TeamsTab({super.key});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
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
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithRetry();
    });
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        await context.read<AcademyProvider>().loadCoachDashboard();
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            String errorMessage = e.toString();
            
            // Handle specific error cases
            if (errorMessage.contains('401') || errorMessage.contains('Unauthorized')) {
              errorMessage = 'Authentication failed. Please log in again.';
            } else if (errorMessage.contains('403') || errorMessage.contains('Forbidden')) {
              errorMessage = 'Access denied. You do not have permission to view coach data.';
            } else if (errorMessage.contains('Cannot read properties of undefined')) {
              errorMessage = 'Connection error. Please check your internet connection.';
            } else if (errorMessage.contains('Network')) {
              errorMessage = 'Network error. Please check your connection and try again.';
            } else if (errorMessage.contains('timeout')) {
              errorMessage = 'Request timeout. Please try again.';
            } else {
              errorMessage = errorMessage.replaceAll('Exception: ', '');
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load coach data: $errorMessage'),
                backgroundColor: Colors.redAccent,
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
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        // Show loading state
        if (provider.isCoachLoading) {
          return const SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Loading Coach Dashboard...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          );
        }

        // Show error state
        if (provider.error != null) {
          return SizedBox(
            height: 400,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceHigh,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: outlineColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Error Loading Data',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 20, 
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.error!,
                            style: const TextStyle(color: outlineColor, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => _loadDataWithRetry(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'RETRY',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900, 
                                  letterSpacing: 2,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show empty state
        if (provider.coachDashboard == null) {
          return const SizedBox(
            height: 400,
            child: Center(
              child: Text(
                'No coach data available',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final dashboard = provider.coachDashboard!;
        final teams = (dashboard['teams'] as List? ?? [])
            .cast<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operations Hub Header
              const Text(
                'OPERATIONS HUB // 04.24',
                style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 4),
              const Text(
                'COMMANDER OVERVIEW',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
              ),
              const SizedBox(height: 32),

              // Active Squads Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ACTIVE SQUADS',
                    style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  Text(
                    'SWIPE TO DRILL DOWN',
                    style: TextStyle(color: outlineColor.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    ...teams.map((team) => _buildSquadCard(team)),
                    _buildAddSquadCard(),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bento Grid - Strategic Intelligence
              _buildNextBattleCard(),
              const SizedBox(height: 16),
              _buildPerformanceRow(),
              const SizedBox(height: 16),
              _buildIntelligenceFeed(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquadCard(Map<String, dynamic> team) {
    final color = Color((team['colorValue'] is int) ? team['colorValue'] as int : primaryColor.value);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailScreen(teamName: team['name']?.toString() ?? ''),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3), 
              blurRadius: 20, 
              offset: const Offset(0, 10)
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.sports_basketball, size: 100, color: Colors.white.withOpacity(0.03)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team['name']?.toString().toUpperCase() ?? 'SQUAD',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
                ),
                Text(
                  team['ageGroup']?.toString().toUpperCase() ?? 'ELITE DIVISION',
                  style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniMetric('88%', 'WIN RATE', primaryColor),
                    _miniMetric('104.2', 'AVG PPG', Colors.white),
                    _miniMetric('#1', 'RANK', const Color(0xFF28D8FF)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
        Text(label, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAddSquadCard() {
    return GestureDetector(
      onTap: () => _showCreateTeamDialog(),
      child: Container(
        width: 180,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: outlineColor.withOpacity(0.2), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: outlineColor.withOpacity(0.3))),
              child: const Icon(Icons.add, color: outlineColor),
            ),
            const SizedBox(height: 12),
            const Text(
              'REGISTER\nNEW SQUAD',
              textAlign: TextAlign.center,
              style: TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextBattleCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceHigh, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEXT BATTLE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('LIVE SCOUTING IN PROGRESS', style: TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('STADIUM: NORTH ARENA', style: TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
                  Text('VS KINGS 19', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCsae0Oq9Kq-clgdaCm9T3cjOP2BdDAJGUHNDzwFJUZG2kOSJxvHLr5_Gwzo5QriHnVYOSyX26PB5HNtPSFR_z36-ONprr8QczHvqarbUS9k0T8IVlxdsk9HiN5Ww4CTifljkBIgUxa0tCGQYIOaYWPP0jBSPR3PpnLg7Ek2L1yFIGuod-gS5Kelq7B7O416-e1w5ZYM-I8m6pGCs8_NvyuVVhCdxMST0JNmiLXgEiRE1mNi_HWEcYAQXAf0RCFJzLbiqG4ytYczZlX'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(16)),
                child: const Text('LAUNCH STRATEGY REEL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow() {
    return Row(
      children: [
        // Top Performer
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceHigh, 
              borderRadius: BorderRadius.circular(24), 
              border: Border(left: BorderSide(color: primaryColor, width: 4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), 
                  blurRadius: 10, 
                  offset: const Offset(0, 4)
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOP PERFORMER', style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Icon(Icons.star, color: primaryColor, size: 14),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: const DecorationImage(image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAS5r7-UjNTYUNiVRabu8WY5a_46n_9v-l4Gtz8YRy30mWBdUJkOllmSki_xn3dgrguULK_0623q-M6yXHiD6sjSw0lBRvZ0PwYPLAgijXncSA6i6H7B27_eWjW84rXlSzAeBtdvlg0KmaJzd_77jtu9cTkQ6QIQQdCCwEtI5G5CXRj2WbPcu2lTUhor2n22ByhlYZFZwFO6FzjMUkiWOIhTbuoppEy2CQ5x1p_F2sizDaQ1kL2mshTnLmgFljBuk69zp-UGl-H77v6'), fit: BoxFit.cover)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MARCUS REED', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('POINT GUARD // #12', style: TextStyle(color: outlineColor, fontSize: 8), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(child: Text('PERFORMANCE INDEX', style: TextStyle(color: outlineColor, fontSize: 7, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    const Text('9.4', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: 0.94, backgroundColor: Colors.white.withOpacity(0.05), color: primaryColor, minHeight: 3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Enroll Athlete Quick Action
        Expanded(
          child: GestureDetector(
            onTap: () {}, // Trigger CreatePlayerFlow
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryColor, Color(0xFFFFDCA3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, color: Colors.black, size: 28),
                  SizedBox(height: 6),
                  Text('ENROLL\nATHLETE', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk', height: 1.1)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntelligenceFeed() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceHigh, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_none, color: outlineColor, size: 18),
              SizedBox(width: 8),
              Text('INTELLIGENCE FEED', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
            ],
          ),
          const SizedBox(height: 16),
          _feedItem('U19 Elite: Performance analysis ready', const Color(0xFF28D8FF), '2M AGO'),
          _feedItem('Medical Alert: J. Thompson (Ankle) update', Colors.redAccent, '1H AGO'),
          _feedItem('Scouting: New prospect matches profile', primaryColor, '5H AGO'),
        ],
      ),
    );
  }

  Widget _feedItem(String text, Color dotColor, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(time, style: const TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCreateTeamDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateTeamDialog(
        onTeamCreated: (name, age, color, logoPath, coachId, assistantId) async {
          final provider = context.read<AcademyProvider>();
          await provider.addTeamToBackend(
            Team(
              id: provider.nextId('t'),
              name: name,
              players: const [],
              ageGroup: age,
              colorValue: color.toARGB32(),
              logoPath: logoPath,
              coachStaffId: coachId,
              assistantCoachStaffId: assistantId,
            ),
          );
          if (context.mounted) Navigator.pop(context);
          // Teams are now handled by AcademyProvider
        },
      ),
    );
  }
}
