import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/features/player/view/player_detail_screen.dart';
import 'package:ballchart/core/widgets/dialogues/CreatePlayerDialog.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';
import '../../../../core/models/local_academy_models.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamName;

  const TeamDetailScreen({super.key, required this.teamName});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _AcademyTheme {
  // BallChart Redesign Tokens - Same as Admin Panel
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color outlineColor = Color(0xFF9D8F79);
  static const Color primaryContainer = Color(0xFFFDB927);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color outline = Color(0xFF9D8F79);
  static const Color tertiaryContainer = Color(0xFF14D7FF);
  static const Color tertiary = Color(0xFFADEBFF);
  static const Color secondaryFixedDim = Color(0xFFE9C400);
  static const Color error = Color(0xFFFFB4AB);

  static const String headlineFont = 'Space Grotesk';
  static const String bodyFont = 'Inter';
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load fresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AcademyProvider>(context, listen: false);
      if (provider.currentUser?.role == 'admin') {
        provider.loadAdminOverview(force: true);
      } else if (['coach', 'assistant_coach', 'head_coach'].contains(provider.currentUser?.role)) {
        provider.loadCoachDashboard(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AcademyTheme.bgColor,
      body: Consumer<AcademyProvider>(
        builder: (context, provider, _) {
          // Try to find team from coach dashboard first, then from academy
          Team? team;
          
          // For coaches, check coach dashboard
          if (provider.coachDashboard != null) {
            final teams = (provider.coachDashboard!['teams'] as List? ?? [])
                .cast<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList();
            
            final teamData = teams.firstWhere(
              (t) => (t['name']?.toString().toLowerCase() ?? '') == widget.teamName.toLowerCase(),
              orElse: () => {},
            );
            
            if (teamData.isNotEmpty) {
              // Convert coach dashboard team data to Team model
              team = Team(
                id: teamData['_id']?.toString() ?? teamData['id']?.toString() ?? '',
                name: teamData['name']?.toString() ?? widget.teamName,
                colorValue: teamData['colorValue'] as int? ?? 0xFFFDB927,
                players: (teamData['players'] as List? ?? []).map<Player>((p) => 
                  Player(
                    id: p['_id']?.toString() ?? p['id']?.toString() ?? '',
                    name: p['name']?.toString() ?? 'Unknown',
                    email: p['email']?.toString() ?? '',
                    position: p['position']?.toString() ?? '',
                    age: p['age'] ?? 18,
                  )
                ).toList(),
                coachStaffId: teamData['coachStaffId']?.toString(),
                assistantCoachStaffId: teamData['assistantCoachStaffId']?.toString(),
              );
            }
          }
          
          // If not found in coach dashboard, try academy (for admin)
          if (team == null) {
            team = provider.academy.teams.firstWhere(
              (t) => t.name.toLowerCase() == widget.teamName.toLowerCase(),
              orElse: () => Team(id: '', name: 'NOT FOUND', players: const []),
            );
          }
          
          if (team.id.isEmpty) {
            return const Center(child: Text('TEAM NOT FOUND', style: TextStyle(color: Colors.white)));
          }

          final teamColor = Color(team.colorValue);
          final coach = team.coachStaffId != null ? provider.getStaffById(team.coachStaffId) : null;
          final assistant = team.assistantCoachStaffId != null ? provider.getStaffById(team.assistantCoachStaffId) : null;

          return RefreshIndicator(
            onRefresh: () async {
              final provider = Provider.of<AcademyProvider>(context, listen: false);
              if (provider.currentUser?.role == 'admin') {
                await provider.loadAdminOverview(force: true);
              } else if (['coach', 'assistant_coach', 'head_coach'].contains(provider.currentUser?.role)) {
                await provider.loadCoachDashboard(force: true);
              }
            },
            color: _AcademyTheme.primaryContainer,
            backgroundColor: _AcademyTheme.surfaceHigh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                _buildSliverAppBar(teamColor),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildTeamIdentity(teamColor, team.ageGroup, team.logoPath, team.id),
                        const SizedBox(height: 32),
                        _buildStatsMetrics(team.players),
                        const SizedBox(height: 40),
                        _buildActiveRoster(team.players, team.id),
                        const SizedBox(height: 40),
                        _buildCommandStaff(
                          coach?.name ?? 'NOT ASSIGNED', 
                          assistant?.name ?? 'NOT ASSIGNED', 
                          team.id, 
                          team.coachStaffId, 
                          team.assistantCoachStaffId, 
                          teamColor
                        ),
                        const SizedBox(height: 40),
                        _buildBattleLog(teamColor, provider.academy.battles, team.players),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AcademyProvider>(
        builder: (context, provider, _) {
          final team = provider.academy.teams.firstWhere(
            (t) => t.name.toLowerCase() == widget.teamName.toLowerCase(),
            orElse: () => Team(id: '', name: '', players: const []),
          );
          if (team.id.isEmpty) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: () => _showAddPlayerDialog(context, team.id),
            backgroundColor: Color(team.colorValue),
            child: const Icon(Icons.person_add_rounded, color: Colors.black),
          );
        }
      ),
    );
  }

  Widget _buildSliverAppBar(Color teamColor) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _AcademyTheme.surfaceDim,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: teamColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: _AcademyTheme.surfaceContainer, shape: BoxShape.circle),
            child: Icon(Icons.shield_rounded, color: teamColor, size: 16),
          ),
          const SizedBox(width: 12),
          Text('ELITE ACADEMY', style: TextStyle(color: teamColor, fontFamily: _AcademyTheme.headlineFont, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_none_rounded, color: teamColor),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTeamIdentity(Color teamColor, String ageGroup, String? logoPath, String teamId) {
    Widget logo;
    if (logoPath != null && logoPath.startsWith('data:')) {
      logo = Image.memory(base64Decode(logoPath.split(',').last), fit: BoxFit.contain, width: 80, height: 80);
    } else if (logoPath != null && logoPath.isNotEmpty) {
      logo = Image.network(logoPath, fit: BoxFit.contain, width: 80, height: 80);
    } else {
      logo = Icon(Icons.sports_basketball_rounded, color: teamColor, size: 80);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _AcademyTheme.surfaceContainer,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: teamColor.withOpacity(0.1), blurRadius: 40)],
          ),
          child: logo,
        ),
        const SizedBox(height: 24),
        Text(widget.teamName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: _AcademyTheme.headlineFont, height: 1)),
        const SizedBox(height: 8),
        Text('DIVISION: $ageGroup', style: TextStyle(color: teamColor.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text('ID: ${teamId.toUpperCase().substring(math.max(0, teamId.length - 8))}', style: const TextStyle(color: _AcademyTheme.outline, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildStatsMetrics(List<Player> players) {
    int totalMatches = 0;
    int totalWins = 0;
    int totalPoints = 0;
    
    for (var p in players) {
      totalMatches += p.matchesPlayed;
      totalWins += p.wins;
      totalPoints += p.points;
    }

    final winRate = totalMatches > 0 ? (totalWins / totalMatches * 100).toStringAsFixed(0) : '0';
    final avgPoints = totalMatches > 0 ? (totalPoints / totalMatches).toStringAsFixed(1) : '0.0';

    return Row(
      children: [
        _metricTile('WIN RATE', '$winRate%', _AcademyTheme.primaryContainer),
        const SizedBox(width: 12),
        _metricTile('AVG POINTS', avgPoints, _AcademyTheme.tertiaryContainer),
        const SizedBox(width: 12),
        _metricTile('SQUAD', '${players.length}', _AcademyTheme.secondaryFixedDim),
      ],
    );
  }

  Widget _metricTile(String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(color: _AcademyTheme.surfaceHigh.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: _AcademyTheme.outline, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: accent, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: _AcademyTheme.headlineFont)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRoster(List<Player> players, String teamId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ACTIVE ROSTER', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: _AcademyTheme.headlineFont)),
            Text('${players.length} PLAYERS', style: const TextStyle(color: _AcademyTheme.primaryContainer, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: players.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == players.length) return _buildAddPlayerPlaceholder(teamId);
              return _buildPlayerScrollCard(players[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerScrollCard(Player player) {
    final winRate = player.matchesPlayed > 0 ? (player.wins / player.matchesPlayed * 100) : 0;
    final bool isElite = winRate > 70;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerDetailScreen(player: player))),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _AcademyTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border(bottom: BorderSide(color: isElite ? _AcademyTheme.primaryContainer : Colors.transparent, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(player.position, style: const TextStyle(color: _AcademyTheme.primaryContainer, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: _AcademyTheme.headlineFont)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: isElite ? _AcademyTheme.primaryContainer : _AcademyTheme.outline, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(isElite ? 'ELITE' : 'GOLD', style: const TextStyle(color: _AcademyTheme.outline, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _AcademyTheme.surfaceHighest),
                child: const Center(child: Icon(Icons.person, color: Colors.white10, size: 60)),
              ),
            ),
            const SizedBox(height: 16),
            Text(player.name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${winRate.toStringAsFixed(0)}%', style: const TextStyle(color: _AcademyTheme.primaryContainer, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: _AcademyTheme.headlineFont)),
                Row(
                  children: [
                    _statMini('PTS', '${player.points}'),
                    const SizedBox(width: 8),
                    _statMini('GS', '${player.matchesPlayed}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statMini(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: _AcademyTheme.outline, fontSize: 7, fontWeight: FontWeight.w900)),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAddPlayerPlaceholder(String? teamId) {
    return GestureDetector(
      onTap: () => _showAddPlayerDialog(context, teamId),
      child: Container(
        width: 170,
        decoration: BoxDecoration(color: _AcademyTheme.surfaceContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05), width: 1, style: BorderStyle.solid)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _AcademyTheme.primaryContainer.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.person_add_rounded, color: _AcademyTheme.primaryContainer, size: 24)),
            const SizedBox(height: 16),
            const Text('ONBOARD PLAYER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandStaff(String head, String asst, String? teamId, String? currentCoachId, String? currentAsstId, Color teamColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('COMMAND STAFF', style: TextStyle(color: teamColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: _AcademyTheme.headlineFont)),
            IconButton(
              onPressed: () => _showAssignStaffDialog(context, teamId, false, currentCoachId, currentAsstId),
              icon: Icon(Icons.settings_suggest_rounded, color: teamColor, size: 20),
              tooltip: 'Assign Staff',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _staffTile(head, 'HEAD COACH', () => _showAssignStaffDialog(context, teamId, false, currentCoachId, currentAsstId)),
            const SizedBox(width: 12),
            _staffTile(asst, 'ASSISTANT', () => _showAssignStaffDialog(context, teamId, true, currentCoachId, currentAsstId)),
          ],
        ),
      ],
    );
  }

  Widget _staffTile(String name, String role, VoidCallback onAssign) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _AcademyTheme.surfaceContainer, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            const CircleAvatar(radius: 24, backgroundColor: _AcademyTheme.surfaceHighest, child: Icon(Icons.face, color: Colors.white24)),
            const SizedBox(height: 12),
            Text(role, style: const TextStyle(color: _AcademyTheme.primaryContainer, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAssign,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: _AcademyTheme.primaryContainer.withOpacity(0.3)), borderRadius: BorderRadius.circular(20)),
                child: const Text('ASSIGN', style: TextStyle(color: _AcademyTheme.primaryContainer, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleLog(Color teamColor, List<Battle> allBattles, List<Player> teamPlayers) {
    final teamPlayerIds = teamPlayers.map((p) => p.id).toSet();
    final teamBattles = allBattles.where((b) {
      return b.participantIds.any((pid) => teamPlayerIds.contains(pid));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('BATTLE LOG', style: TextStyle(color: teamColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: _AcademyTheme.headlineFont)),
            const Text('RECENT SQUADS', style: TextStyle(color: _AcademyTheme.outline, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 16),
        if (teamBattles.isEmpty)
          const Center(child: Text('NO RECENT BATTLES', style: TextStyle(color: _AcademyTheme.outline, fontSize: 12)))
        else
          ...teamBattles.take(3).map((battle) {
            final isWin = battle.result?.contains('WIN') ?? false;
            return _logTile(battle.location, battle.status.toUpperCase(), battle.result ?? 'PND', '', isWin, teamColor);
          }),
      ],
    );
  }

  Widget _logTile(String opponent, String date, String scoreA, String scoreB, bool isWin, Color teamColor) {
    return Opacity(
      opacity: isWin ? 1.0 : 0.7,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _AcademyTheme.surfaceContainer, borderRadius: BorderRadius.circular(20)),
        child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: _AcademyTheme.surfaceDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))), child: const Center(child: Text('TA', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opponent, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(date, style: const TextStyle(color: _AcademyTheme.outline, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(scoreA, style: TextStyle(color: isWin ? teamColor : Colors.white24, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: _AcademyTheme.headlineFont)),
                  const Text(' - ', style: TextStyle(color: Colors.white24)),
                  Text(scoreB, style: TextStyle(color: isWin ? Colors.white24 : _AcademyTheme.error, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: _AcademyTheme.headlineFont)),
                ],
              ),
              Text(isWin ? 'VICTORY' : 'DEFEAT', style: TextStyle(color: isWin ? teamColor : _AcademyTheme.error, fontSize: 8, fontWeight: FontWeight.w900)),
            ],
          ),
          ],
        ),
      ),
    );
  }

  void _showAssignStaffDialog(BuildContext context, String? teamId, bool isAssistant, String? currentCoachId, String? currentAsstId) {
    if (teamId == null) return;
    
    final provider = context.read<AcademyProvider>();
    final allStaff = provider.academy.staff;
    
    if (allStaff.isEmpty) {
      provider.loadAdminOverview();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _AcademyTheme.surfaceDim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isAssistant ? 'CHOOSE ASSISTANT COACH' : 'CHOOSE HEAD COACH', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: _AcademyTheme.headlineFont)),
              const SizedBox(height: 16),
              const Text('ONLY REGISTERED PERSONNEL ARE DISCOVERABLE', style: TextStyle(color: _AcademyTheme.outline, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: allStaff.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final staff = allStaff[index];
                    return ListTile(
                      onTap: () async {
                        await provider.assignTeamLeadsInBackend(
                          teamId: teamId,
                          coachStaffId: isAssistant ? currentCoachId : staff.id,
                          assistantCoachStaffId: isAssistant ? staff.id : currentAsstId,
                        );
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() {}); // Re-fetch dashboard data via FutureBuilder
                        }
                      },
                      leading: const CircleAvatar(backgroundColor: _AcademyTheme.surfaceContainer, child: Icon(Icons.face, color: _AcademyTheme.primaryContainer, size: 20)),
                      title: Text(staff.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text(staff.role.toUpperCase(), style: const TextStyle(color: _AcademyTheme.outline, fontSize: 10)),
                      trailing: const Icon(Icons.add_circle_outline_rounded, color: _AcademyTheme.primaryContainer),
                      tileColor: _AcademyTheme.surfaceContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _showAddPlayerDialog(BuildContext context, String? teamId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CreatePlayerDialog(
          teamId: teamId,
          onPlayerCreated: (playerData) {
            setState(() {});
          },
        ),
      ),
    );
  }
}

class Position8 extends StatelessWidget {
  final double? left, top, right, bottom;
  final Widget child;
  const Position8({super.key, this.left, this.top, this.right, this.bottom, required this.child});
  @override
  Widget build(BuildContext context) => Positioned(left: left, top: top, right: right, bottom: bottom, child: child);
}
