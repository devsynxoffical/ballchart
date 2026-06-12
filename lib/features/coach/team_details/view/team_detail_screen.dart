import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ballchart/features/player/view/player_detail_screen.dart';
import 'package:ballchart/core/widgets/dialogues/CreatePlayerDialog.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';
import 'package:ballchart/core/services/api_service.dart';
import '../../../../core/models/local_academy_models.dart';

String _formatDivisionLabel(String ageGroup) {
  final raw = ageGroup.trim().toUpperCase().replaceAll('U-', 'U').replaceAll(' ', '');
  if (raw.isEmpty || raw == 'OPEN') return 'Open Division';
  return '$raw Division';
}

class TeamDetailScreen extends StatefulWidget {
  final String teamName;
  final String? teamId;

  const TeamDetailScreen({super.key, required this.teamName, this.teamId});

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
      _loadDataWithRetry();
    });
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final provider = Provider.of<AcademyProvider>(context, listen: false);
        if (provider.currentUser?.role == 'admin') {
          await provider.loadAdminOverview(force: true);
        } else if (['coach', 'assistant_coach', 'head_coach'].contains(provider.currentUser?.role)) {
          await provider.loadCoachDashboard(force: true);
        }
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load team data: ${e.toString()}'),
                backgroundColor: Colors.red,
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

  static String? _refId(dynamic v) {
    if (v == null) return null;
    if (v is Map) return v['_id']?.toString();
    return v.toString();
  }

  Player _playerFromCoachMap(Map<String, dynamic> p) {
    final stats = (p['stats'] is Map) ? Map<String, dynamic>.from(p['stats'] as Map) : <String, dynamic>{};
    final ageText = (p['ageRange'] ?? p['age'] ?? '16').toString();
    final age = int.tryParse(RegExp(r'\d+').firstMatch(ageText)?.group(0) ?? '16') ?? 16;
    return Player(
      id: (p['_id'] ?? p['id'] ?? '').toString(),
      name: (p['username'] ?? p['name'] ?? 'Unknown Player').toString(),
      email: (p['email'] ?? p['loginEmail'] ?? (p['user'] is Map ? p['user']['email']?.toString() : null) ?? '').toString(),
      position: (p['position'] ?? 'Player').toString(),
      age: age,
      matchesPlayed: (stats['matchesPlayed'] as num?)?.toInt() ?? 0,
      wins: (stats['wins'] as num?)?.toInt() ?? 0,
      points: (stats['points'] as num?)?.toInt() ?? 0,
      tempPassword: p['tempPassword']?.toString() ??
          p['password']?.toString() ??
          (p['credentials'] is Map ? p['credentials']['tempPassword']?.toString() : null),
      height: p['height']?.toString() ?? 'N/A',
      weight: p['weight']?.toString() ?? 'N/A',
      wingspan: p['wingspan']?.toString() ?? 'N/A',
      classYear: p['classYear']?.toString() ?? 'N/A',
      isEliteProspect: p['isEliteProspect'] as bool? ?? false,
      profileImageUrl: () {
        final raw = p['profileImageUrl']?.toString().trim();
        if (raw == null || raw.isEmpty) return null;
        final u = ApiService.resolveMediaUrl(raw);
        return u.isEmpty ? null : u;
      }(),
    );
  }

  Team? _teamFromDashboardMap(Map<String, dynamic> teamData) {
    final id = teamData['_id']?.toString() ?? teamData['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    final players = <Player>[];
    for (final p in (teamData['players'] as List? ?? [])) {
      if (p is Map) {
        final pl = _playerFromCoachMap(Map<String, dynamic>.from(p));
        if (pl.id.isNotEmpty) players.add(pl);
      }
    }
    final cv = teamData['colorValue'];
    return Team(
      id: id,
      name: teamData['name']?.toString() ?? widget.teamName,
      ageGroup: teamData['ageGroup']?.toString() ?? 'Open',
      colorValue: cv is int ? cv : 0xFFFDB927,
      logoPath: teamData['logoPath']?.toString(),
      players: players,
      coachStaffId: _refId(teamData['coachStaffId']),
      assistantCoachStaffId: _refId(teamData['assistantCoachStaffId']),
    );
  }

  /// Coach dashboard row if present, else academy [Team], plus optional raw map for populated staff names.
  (Team, Map<String, dynamic>?)? _resolveTeam(AcademyProvider provider) {
    if (provider.coachDashboard != null) {
      final teams = (provider.coachDashboard!['teams'] as List? ?? [])
          .map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();

      Map<String, dynamic>? teamData;
      if (widget.teamId != null && widget.teamId!.isNotEmpty) {
        for (final t in teams) {
          if (t['_id']?.toString() == widget.teamId) {
            teamData = t;
            break;
          }
        }
      }
      teamData ??= () {
        try {
          return teams.firstWhere(
            (t) => (t['name']?.toString().toLowerCase() ?? '') == widget.teamName.toLowerCase(),
          );
        } catch (_) {
          return null;
        }
      }();

      if (teamData != null) {
        final team = _teamFromDashboardMap(teamData);
        if (team != null) return (team, teamData);
      }
    }

    try {
      final t = provider.academy.teams.firstWhere((x) {
        if (widget.teamId != null && widget.teamId!.isNotEmpty) return x.id == widget.teamId;
        return x.name.toLowerCase() == widget.teamName.toLowerCase();
      });
      if (t.id.isEmpty) return null;
      return (t, null);
    } catch (_) {
      return null;
    }
  }

  String _leadDisplayName(AcademyProvider provider, Map<String, dynamic>? raw, String key, String? staffId) {
    if (raw != null) {
      final v = raw[key];
      if (v is Map && (v['username'] != null)) return v['username'].toString();
    }
    if (staffId != null && staffId.isNotEmpty) {
      return provider.getStaffById(staffId)?.name ?? 'NOT ASSIGNED';
    }
    return 'NOT ASSIGNED';
  }

  /// Resolved photo URL for command staff (dashboard populated staff or local academy.staff).
  String? _leadProfilePicUrl(AcademyProvider provider, Map<String, dynamic>? raw, String key, String? staffId) {
    if (raw != null) {
      final v = raw[key];
      if (v is Map) {
        final pic = v['profilePic'] ?? v['profileImageUrl'];
        if (pic != null && pic.toString().trim().isNotEmpty) {
          final u = ApiService.resolveMediaUrl(pic.toString());
          return u.isEmpty ? null : u;
        }
      }
    }
    final staff = provider.getStaffById(staffId);
    final pic = staff?.profilePic?.trim();
    if (pic != null && pic.isNotEmpty) {
      final u = ApiService.resolveMediaUrl(pic);
      return u.isEmpty ? null : u;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AcademyTheme.bgColor,
      body: Consumer<AcademyProvider>(
        builder: (context, provider, _) {
          final resolved = _resolveTeam(provider);
          if (resolved == null) {
            return const Center(child: Text('TEAM NOT FOUND', style: TextStyle(color: Colors.white)));
          }
          final team = resolved.$1;
          final teamRaw = resolved.$2;
          final canAssignLeads = provider.currentUser?.role == 'admin';

          final teamColor = Color(team.colorValue);
          final coachName = _leadDisplayName(provider, teamRaw, 'coachStaffId', team.coachStaffId);
          final asstName = _leadDisplayName(provider, teamRaw, 'assistantCoachStaffId', team.assistantCoachStaffId);
          final coachPic = _leadProfilePicUrl(provider, teamRaw, 'coachStaffId', team.coachStaffId);
          final asstPic = _leadProfilePicUrl(provider, teamRaw, 'assistantCoachStaffId', team.assistantCoachStaffId);

          return RefreshIndicator(
            onRefresh: () => _loadDataWithRetry(),
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
                        _buildTeamIdentity(teamColor, team, provider),
                        const SizedBox(height: 32),
                        _buildStatsMetrics(team.players),
                        const SizedBox(height: 40),
                        _buildActiveRoster(team.players, team.id),
                        const SizedBox(height: 40),
                        _buildCommandStaff(
                          coachName,
                          asstName,
                          coachPic,
                          asstPic,
                          team.id,
                          team.coachStaffId,
                          team.assistantCoachStaffId,
                          teamColor,
                          canAssignLeads,
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
          final resolved = _resolveTeam(provider);
          if (resolved == null) return const SizedBox.shrink();
          final team = resolved.$1;
          return FloatingActionButton(
            heroTag: 'team_detail_add_player_fab',
            onPressed: () => _showAddPlayerDialog(context, team.id),
            backgroundColor: Color(team.colorValue),
            child: const Icon(Icons.person_add_rounded, color: Colors.black),
          );
        },
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

  Future<void> _pickAndUpdateTeamLogo(Team team, AcademyProvider provider) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final updated = Team(
      id: team.id,
      name: team.name,
      ageGroup: team.ageGroup,
      colorValue: team.colorValue,
      logoPath: dataUri,
      players: team.players,
      coachStaffId: team.coachStaffId,
      assistantCoachStaffId: team.assistantCoachStaffId,
    );
    await provider.updateTeamInBackend(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team photo updated'), backgroundColor: _AcademyTheme.primaryColor),
      );
    }
  }

  Widget _buildTeamIdentity(Color teamColor, Team team, AcademyProvider provider) {
    final ageGroup = team.ageGroup;
    final logoPath = team.logoPath;
    Widget logo;
    if (logoPath != null && logoPath.startsWith('data:')) {
      logo = Image.memory(base64Decode(logoPath.split(',').last), fit: BoxFit.contain, width: 80, height: 80);
    } else if (logoPath != null && logoPath.isNotEmpty) {
      final url = ApiService.resolveMediaUrl(logoPath);
      logo = url.isEmpty
          ? Icon(Icons.sports_basketball_rounded, color: teamColor, size: 80)
          : Image.network(
              url,
              fit: BoxFit.contain,
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) => Icon(Icons.sports_basketball_rounded, color: teamColor, size: 80),
            );
    } else {
      logo = Icon(Icons.sports_basketball_rounded, color: teamColor, size: 80);
    }

    return Column(
      children: [
        InkWell(
          onTap: () => _pickAndUpdateTeamLogo(team, provider),
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _AcademyTheme.surfaceContainer,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: teamColor.withOpacity(0.1), blurRadius: 40)],
            ),
            child: logo,
          ),
        ),
        const SizedBox(height: 6),
        Text('Tap logo to change team photo', style: TextStyle(color: teamColor.withOpacity(0.65), fontSize: 10)),
        const SizedBox(height: 24),
        Text(widget.teamName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: _AcademyTheme.headlineFont, height: 1)),
        const SizedBox(height: 8),
        Text(_formatDivisionLabel(ageGroup), style: TextStyle(color: teamColor.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: player.profileImageUrl != null && player.profileImageUrl!.isNotEmpty
                      ? Image.network(
                          player.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.person, color: Colors.white10, size: 60));
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(color: _AcademyTheme.primaryContainer, strokeWidth: 2),
                            );
                          },
                        )
                      : const Center(child: Icon(Icons.person, color: Colors.white10, size: 60)),
                ),
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

  Widget _buildCommandStaff(
    String head,
    String asst,
    String? headPicUrl,
    String? asstPicUrl,
    String? teamId,
    String? currentCoachId,
    String? currentAsstId,
    Color teamColor,
    bool canAssignLeads,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('COACHING STAFF', style: TextStyle(color: teamColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: _AcademyTheme.headlineFont)),
            if (canAssignLeads)
              IconButton(
                onPressed: () => _showAssignStaffDialog(context, teamId, false, currentCoachId, currentAsstId),
                icon: Icon(Icons.settings_suggest_rounded, color: teamColor, size: 20),
                tooltip: 'Assign Staff',
              )
            else
              const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _staffTile(
              head,
              'HEAD COACH',
              headPicUrl,
              canAssignLeads ? () => _showAssignStaffDialog(context, teamId, false, currentCoachId, currentAsstId) : null,
            ),
            const SizedBox(width: 12),
            _staffTile(
              asst,
              'ASSISTANT',
              asstPicUrl,
              canAssignLeads ? () => _showAssignStaffDialog(context, teamId, true, currentCoachId, currentAsstId) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _staffPhotoAvatar(String? imageUrl) {
    const double r = 28;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: r * 2,
          height: r * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _staffPhotoPlaceholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: r * 2,
              height: r * 2,
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _AcademyTheme.primaryContainer),
                ),
              ),
            );
          },
        ),
      );
    }
    return _staffPhotoPlaceholder();
  }

  Widget _staffPhotoPlaceholder() {
    return CircleAvatar(
      radius: 28,
      backgroundColor: _AcademyTheme.surfaceHighest,
      child: const Icon(Icons.person, color: Colors.white24, size: 28),
    );
  }

  Widget _staffTile(String name, String role, String? imageUrl, VoidCallback? onAssign) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _AcademyTheme.surfaceContainer, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            _staffPhotoAvatar(imageUrl),
            const SizedBox(height: 12),
            Text(role, style: const TextStyle(color: _AcademyTheme.primaryContainer, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (onAssign != null) ...[
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
    if (provider.currentUser?.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the academy admin can assign coaches to teams.')),
      );
      return;
    }

    var allStaff = provider.getStaffListForAssignments();
    if (allStaff.isEmpty) {
      provider.loadAdminOverview();
      allStaff = provider.getStaffListForAssignments();
    }

    final eligible = allStaff.where((s) {
      return s.id != currentCoachId && s.id != currentAsstId;
    }).toList();

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
              const Text('STAFF ALREADY ON THIS TEAM ARE HIDDEN. ADMIN ONLY.', style: TextStyle(color: _AcademyTheme.outline, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 24),
              Flexible(
                child: eligible.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No other staff available to assign.', style: TextStyle(color: _AcademyTheme.outline)),
                        ),
                      )
                    : ListView.separated(
                  shrinkWrap: true,
                  itemCount: eligible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final staff = eligible[index];
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
