import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add for Clipboard
import 'package:provider/provider.dart';
import 'package:ballchart/core/models/local_academy_models.dart';
import 'package:ballchart/core/models/battle_model.dart';
import 'package:ballchart/core/repositories/profile_repository.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';

class PlayerDetailScreen extends StatefulWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Load fresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithRetry();
    });
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final provider = Provider.of<AcademyProvider>(context, listen: false);
        if (provider.currentUser?.role == 'player') {
          await provider.loadPlayerDashboard(force: true);
        }
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load player data: ${e.toString().replaceAll('Exception: ', '')}'),
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

  static const Color primaryContainer = Color(0xFFFDB927);
  static const Color background = Color(0xFF131313);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color outline = Color(0xFF9D8F79);
  static const Color tertiaryContainer = Color(0xFF14D7FF);
  static const Color tertiary = Color(0xFFADEBFF);
  static const Color secondaryFixedDim = Color(0xFFE9C400);
  static const Color error = Color(0xFFFFB4AB);

  static const String headlineFont = 'Space Grotesk';
  static const String bodyFont = 'Inter';

  @override
  Widget build(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final currentUser = provider.currentUser;
        final isOwnProfile = currentUser?.role == 'player' || currentUser?.role == null;
        
        return Scaffold(
          backgroundColor: background,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: _buildContent(context),
              ),
            ],
          ),
          floatingActionButton: isOwnProfile
            ? FloatingActionButton(
                backgroundColor: primaryContainer,
                onPressed: () {
                  final dashboard = provider.playerDashboard;
                  if (dashboard != null) {
                    final playerData = dashboard['player'] as Map<String, dynamic>? ?? {};
                    _showEditBiometricsDialog(context, playerData);
                  }
                },
                child: const Icon(Icons.edit, color: Colors.black),
                tooltip: 'Edit Profile',
              )
            : null,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroProfile(widget.player.name),
        _buildBiometricsBento(),
        _buildCredentialsSection(), 
        _buildPerformanceStats(),
        _buildBattleStats(),
        _buildScoutingNotes(),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildCredentialsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACCOUNT CREDENTIALS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: headlineFont)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _credentialTile('LOGIN EMAIL', widget.player.email, Icons.email_outlined),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white10)),
                _credentialTile(
                  'SECURED PASSWORD', 
                  widget.player.tempPassword ?? '••••••••', 
                  Icons.lock_outline_rounded,
                  isPassword: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _credentialTile(String label, String value, IconData icon, {bool isPassword = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: primaryContainer, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: outline, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold, fontFamily: bodyFont)),
              const SizedBox(height: 4),
              Text(
                isPassword && !_isPasswordVisible ? '••••••••' : value,
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: bodyFont),
              ),
            ],
          ),
        ),
        if (isPassword)
          IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: outline, size: 18),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, color: outline, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('COPIED TO CLIPBOARD', style: TextStyle(fontWeight: FontWeight.bold))));
          },
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: surfaceDim,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryContainer, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: surfaceContainer, shape: BoxShape.circle),
            child: Icon(Icons.shield_rounded, color: primaryContainer, size: 16),
          ),
          const SizedBox(width: 12),
          Text('ELITE ACADEMY', style: TextStyle(color: primaryContainer, fontFamily: headlineFont, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
        ],
      ),
      actions: [
        Consumer<AcademyProvider>(
          builder: (context, provider, _) {
            final currentUser = provider.currentUser;
            final isOwnProfile = currentUser?.role == 'player' || currentUser?.role == null;
            
            if (isOwnProfile) {
              return IconButton(
                icon: const Icon(Icons.edit_outlined, color: primaryContainer),
                onPressed: () {
                  final dashboard = provider.playerDashboard;
                  if (dashboard != null) {
                    final playerData = dashboard['player'] as Map<String, dynamic>? ?? {};
                    _showEditBiometricsDialog(context, playerData);
                  }
                },
                tooltip: 'Edit Profile',
              );
            }
            return IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: primaryContainer),
              onPressed: () {},
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeroProfile(String name) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final dashboard = provider.playerDashboard;
        final error = provider.error;
        final currentUser = provider.currentUser;
        final isOwnProfile = currentUser?.role == 'player' || currentUser?.role == null;
        
        // For coaches viewing other players, use widget.player data directly
        if (!isOwnProfile) {
          return _buildPlayerHeroContent(
            name: widget.player.name,
            isEliteProspect: widget.player.isEliteProspect,
            classYear: widget.player.classYear,
            position: widget.player.position,
          );
        }
        
        // For players viewing their own profile
        if (provider.isPlayerLoading) {
          return const SizedBox(
            height: 380,
            child: Center(child: CircularProgressIndicator(color: primaryContainer)),
          );
        }
        
        if (error != null) {
          return SizedBox(
            height: 380,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.withOpacity(0.7), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load player data',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.replaceAll('Failed to load player dashboard: ', ''),
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadDataWithRetry(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryContainer,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        final playerData = dashboard?['player'] as Map<String, dynamic>? ?? {};
        final isEliteProspect = playerData['isEliteProspect'] ?? widget.player.isEliteProspect;
        final classYear = playerData['classYear'] ?? widget.player.classYear;
        
        return _buildPlayerHeroContent(
          name: widget.player.name,
          isEliteProspect: isEliteProspect,
          classYear: classYear,
          position: widget.player.position,
        );
      },
    );
  }
  
  Widget _buildPlayerHeroContent({
    required String name,
    required bool isEliteProspect,
    required String classYear,
    required String position,
  }) {
        
        return RelativeStack(
          children: [
            SizedBox(
              height: 380,
              width: double.infinity,
              child: Image.network(
                'https://picsum.photos/seed/player-${widget.player.id}/800/600.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [surfaceHigh, surfaceDim],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.person, color: Colors.white24, size: 80),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              top: 24,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [background.withOpacity(0), background.withOpacity(0.4), background],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isEliteProspect)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(color: primaryContainer, borderRadius: BorderRadius.circular(2)),
                            child: const Text('ELITE PROSPECT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: bodyFont)),
                          ),
                        Text(classYear.toString().toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2, fontFamily: bodyFont)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name.toUpperCase().replaceAll(' ', '\n'), 
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1.0, fontFamily: headlineFont),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _infoBit('POSITION', position),
                        const SizedBox(width: 24),
                        Container(width: 1, height: 32, color: Colors.white10),
                        const SizedBox(width: 24),
                        _infoBit('JERSEY', widget.player.jerseyNumber, isPrimary: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
  }

  Widget _infoBit(String label, String value, {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: outline, fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.bold, fontFamily: bodyFont)),
        Text(value, style: TextStyle(color: isPrimary ? primaryContainer : Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: headlineFont)),
      ],
    );
  }

  Widget _buildBiometricsBento() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final dashboard = provider.playerDashboard;
        final error = provider.error;
        final currentUser = provider.currentUser;
        final isOwnProfile = currentUser?.role == 'player' || currentUser?.role == null;
        
        // For coaches viewing other players, use widget.player data directly
        if (!isOwnProfile) {
          return _buildBiometricsContent(
            height: widget.player.height,
            weight: widget.player.weight,
            wingspan: widget.player.wingspan,
            age: widget.player.age.toString(),
            isOwnProfile: false,
          );
        }
        
        // For players viewing their own profile
        if (provider.isPlayerLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: primaryContainer)),
          );
        }
        
        if (error != null) {
          return const SizedBox.shrink(); // Don't show biometrics if there's an error
        }

        final playerData = dashboard?['player'] as Map<String, dynamic>? ?? {};
        
        return _buildBiometricsContent(
          height: playerData['height'] ?? widget.player.height,
          weight: playerData['weight'] ?? widget.player.weight,
          wingspan: playerData['wingspan'] ?? widget.player.wingspan,
          age: (playerData['age'] ?? widget.player.age).toString(),
          isOwnProfile: isOwnProfile,
        );
      },
    );
  }
  
  Widget _buildBiometricsContent({
    required String height,
    required String weight,
    required String wingspan,
    required String age,
    required bool isOwnProfile,
  }) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('BIOMETRICS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: headlineFont)),
                  if (isOwnProfile)
                    Container(
                      decoration: BoxDecoration(
                        color: primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, color: primaryContainer, size: 20),
                        onPressed: () {}, // Edit not available in extracted method
                        tooltip: 'Edit Profile',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _biometricBit(Icons.height, 'Height', height)),
                  const SizedBox(width: 12),
                  Expanded(child: _biometricBit(Icons.monitor_weight_outlined, 'Weight', weight)),
                  const SizedBox(width: 12),
                  Expanded(child: _biometricBit(Icons.straighten, 'Wingspan', wingspan)),
                ],
              ),
            ],
          ),
        );
  }

  Widget _biometricBit(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(icon, color: primaryContainer, size: 24),
          const SizedBox(height: 8),
          Text(label.toUpperCase(), style: TextStyle(color: outline, fontSize: 9, letterSpacing: 1, fontFamily: bodyFont)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: bodyFont)),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final currentUser = provider.currentUser;
        final isOwnProfile = currentUser?.role == 'player' || currentUser?.role == null;
        
        // For coaches viewing other players, use widget.player stats directly
        if (!isOwnProfile) {
          return _buildPerformanceContent(
            ppg: widget.player.ppg,
            apg: widget.player.apg,
            rpg: widget.player.rpg,
            matchesPlayed: widget.player.matchesPlayed,
            wins: widget.player.wins,
          );
        }
        
        // For players viewing their own profile
        if (provider.isPlayerLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: primaryContainer)),
          );
        }
        
        final dashboard = provider.playerDashboard;
        if (dashboard == null) {
          return const SizedBox.shrink();
        }
        
        final playerData = dashboard['player'] as Map<String, dynamic>? ?? {};
        final stats = playerData['stats'] as Map<String, dynamic>? ?? playerData;
        
        return _buildPerformanceContent(
          ppg: (stats['ppg'] ?? widget.player.ppg).toDouble(),
          apg: (stats['apg'] ?? widget.player.apg).toDouble(),
          rpg: (stats['rpg'] ?? widget.player.rpg).toDouble(),
          matchesPlayed: stats['matchesPlayed'] ?? widget.player.matchesPlayed,
          wins: stats['wins'] ?? widget.player.wins,
        );
      },
    );
  }
  
  Widget _buildPerformanceContent({
    required double ppg,
    required double apg,
    required double rpg,
    required int matchesPlayed,
    required int wins,
  }) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SEASON PERFORMANCE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: headlineFont)),
                  Text('LAST 10 GAMES', style: TextStyle(color: primaryContainer, fontSize: 10, letterSpacing: 2, fontFamily: bodyFont)),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _statTile('PPG', ppg.toStringAsFixed(1), 'SEASON AVG', true),
                  const SizedBox(width: 16),
                  _statTile('APG', apg.toStringAsFixed(1), 'SEASON AVG', true),
                  const SizedBox(width: 16),
                  _statTile('RPG', rpg.toStringAsFixed(1), 'SEASON AVG', true),
                ],
              ),
            ),
          ],
        );
  }

  Widget _statTile(String label, String value, String change, bool isPositive) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 2, height: 16, color: isPositive ? primaryContainer : outline),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: outline, fontSize: 10, letterSpacing: 2, fontFamily: bodyFont)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: headlineFont)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: isPositive ? tertiary : Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Text(change, style: TextStyle(color: isPositive ? tertiary : Colors.redAccent, fontSize: 10, fontFamily: bodyFont)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBattleStats() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final currentUser = provider.currentUser;
        final isOwnProfile = currentUser?.role == 'player' || currentUser?.role == null;
        
        // For coaches viewing other players, use widget.player stats directly
        if (!isOwnProfile) {
          return _buildBattleContent(
            totalBattles: widget.player.matchesPlayed,
            wins: widget.player.wins,
            points: widget.player.points,
            teamName: 'N/A',
            isOwnProfile: false,
            battleStats: null,
          );
        }
        
        // For players viewing their own profile
        if (provider.isPlayerLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: primaryContainer)),
          );
        }
        
        final dashboard = provider.playerDashboard;
        if (dashboard == null) {
          return const SizedBox.shrink();
        }
        
        final playerData = dashboard['player'] as Map<String, dynamic>? ?? {};
        final stats = playerData['stats'] as Map<String, dynamic>? ?? playerData;
        final battleStats = playerData['battleStats'] as Map<String, dynamic>? ?? {};
        
        return _buildBattleContent(
          totalBattles: battleStats['totalBattles'] ?? widget.player.matchesPlayed,
          wins: battleStats['wins'] ?? widget.player.wins,
          points: battleStats['totalPoints'] ?? stats['points'] ?? widget.player.points,
          teamName: playerData['teamName'] ?? 'UNASSIGNED',
          isOwnProfile: true,
          battleStats: battleStats,
        );
      },
    );
  }
  
  Widget _buildBattleContent({
    required int totalBattles,
    required int wins,
    required int points,
    required String teamName,
    required bool isOwnProfile,
    Map<String, dynamic>? battleStats,
  }) {
        final losses = totalBattles - wins;
        final winRate = totalBattles > 0 ? ((wins / totalBattles) * 100).round() : 0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('BATTLE PERFORMANCE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: headlineFont)),
                  Text('CAREER STATS', style: TextStyle(color: primaryContainer, fontSize: 10, letterSpacing: 2, fontFamily: bodyFont)),
                ],
              ),
            ),
            // Team Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryContainer.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryContainer.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.group, color: primaryContainer, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CURRENT TEAM', style: TextStyle(color: outline, fontSize: 10, letterSpacing: 2, fontFamily: bodyFont)),
                              Text(teamName, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: headlineFont)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Battle Stats Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _battleStatTile('WINS', wins.toString(), 'Victories', true),
                  const SizedBox(width: 16),
                  _battleStatTile('LOSSES', losses.toString(), 'Defeats', false),
                  const SizedBox(width: 16),
                  _battleStatTile('WIN %', '$winRate%', 'Win Rate', winRate >= 50),
                  const SizedBox(width: 16),
                  _battleStatTile('POINTS', points.toString(), 'Total Points', true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Recent Battles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RECENT BATTLES', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: headlineFont)),
                    const SizedBox(height: 16),
                    if (!isOwnProfile)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: surfaceContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text('Battle history available for own profile only', style: TextStyle(color: outline, fontSize: 14, fontFamily: bodyFont)),
                        ),
                      )
                    else if (battleStats?['recentBattles'] != null && battleStats?['recentBattles'].isNotEmpty == true)
                      ...(battleStats?['recentBattles'] ?? []).take(3).map((battle) => _recentBattleItem(battle)).toList()
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: surfaceContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text('No recent battles', style: TextStyle(color: outline, fontSize: 14, fontFamily: bodyFont)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
  }

  Widget _battleStatTile(String label, String value, String subtitle, bool isPositive) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPositive ? primaryContainer.withOpacity(0.1) : surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPositive ? primaryContainer.withOpacity(0.3) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: outline, fontSize: 10, letterSpacing: 2, fontFamily: bodyFont)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: isPositive ? primaryContainer : Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: headlineFont)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: outline, fontSize: 9, fontFamily: bodyFont)),
        ],
      ),
    );
  }

  Widget _recentBattleItem(Map<String, dynamic> battle) {
    final isWin = battle['result'] == 'win';
    final opponent = battle['opponent'] ?? 'Unknown';
    final points = battle['points'] ?? 0;
    final date = battle['date'] ?? 'Recent';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: isWin ? primaryContainer : Colors.redAccent, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isWin ? primaryContainer.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(isWin ? Icons.emoji_events : Icons.sports_kabaddi, 
                       color: isWin ? primaryContainer : Colors.redAccent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('vs $opponent', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: bodyFont)),
                Text(date, style: TextStyle(color: outline, fontSize: 12, fontFamily: bodyFont)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(isWin ? 'WIN' : 'LOSS', style: TextStyle(color: isWin ? primaryContainer : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: bodyFont)),
              Text('$points pts', style: TextStyle(color: outline, fontSize: 10, fontFamily: bodyFont)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoutingNotes() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final currentUser = provider.currentUser;
        final isOwnProfile = currentUser?.role == 'player' || currentUser?.role == null;
        final dashboard = (isOwnProfile ? provider.playerDashboard : {'player': {}}) ?? {'player': {}};
        final error = provider.error;
        
        if (isOwnProfile && (provider.isPlayerLoading || provider.playerDashboard == null)) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: primaryContainer)),
          );
        }
        
        if (error != null && error.contains('player dashboard')) {
          return const SizedBox.shrink(); // Don't show scouting notes if there's an error
        }

        final playerData = dashboard['player'] as Map<String, dynamic>? ?? {};
        final scoutingNotes = playerData['scoutingNotes'] ?? widget.player.scoutingNotes;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SCOUTING NOTES', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: headlineFont)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(20)),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -10,
                      right: -10,
                      child: Icon(Icons.format_quote_rounded, color: Colors.white10, size: 80),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (scoutingNotes.toString() ?? '"No tactical analysis recorded yet for this prospect."').isEmpty 
                            ? '"No tactical analysis recorded yet for this prospect."' 
                            : '"${scoutingNotes}"',
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic, height: 1.6, fontFamily: bodyFont),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(width: 24, height: 24, decoration: BoxDecoration(color: primaryContainer.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.verified, color: primaryContainer, size: 12)),
                            const SizedBox(width: 8),
                            const Text('HEAD COACH ANALYSIS', style: TextStyle(color: outline, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: bodyFont)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditBiometricsDialog(BuildContext context, Map<String, dynamic> playerData) {
    final heightController = TextEditingController(text: playerData['height']?.toString() ?? widget.player.height);
    final weightController = TextEditingController(text: playerData['weight']?.toString() ?? widget.player.weight);
    final wingspanController = TextEditingController(text: playerData['wingspan']?.toString() ?? widget.player.wingspan);
    final positionController = TextEditingController(text: playerData['position']?.toString() ?? widget.player.position);
    final jerseyController = TextEditingController(text: playerData['jerseyNumber']?.toString() ?? widget.player.jerseyNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceContainer,
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontFamily: headlineFont)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: heightController,
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: wingspanController,
                decoration: InputDecoration(
                  labelText: 'Wingspan (cm)',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: positionController,
                decoration: InputDecoration(
                  labelText: 'Position',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: jerseyController,
                decoration: InputDecoration(
                  labelText: 'Jersey Number',
                  labelStyle: TextStyle(color: outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryContainer)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: outline)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final profileRepository = ProfileRepository();
                await profileRepository.completeProfile({
                  'height': heightController.text,
                  'weight': weightController.text,
                  'wingspan': wingspanController.text,
                  'position': positionController.text,
                  'jerseyNumber': jerseyController.text,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  // Refresh the dashboard data
                  final provider = Provider.of<AcademyProvider>(context, listen: false);
                  await provider.loadPlayerDashboard(force: true);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!', style: TextStyle(color: Colors.black)),
                      backgroundColor: primaryContainer,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating profile: $e', style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryContainer),
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class RelativeStack extends StatelessWidget {
  final List<Widget> children;
  const RelativeStack({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Stack(children: children);
  }
}
