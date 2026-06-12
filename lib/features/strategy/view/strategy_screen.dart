import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/basketball_strategy.dart';
import '../../../core/models/strategy_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/dialogues/CreateStrategyDialog.dart';
import '../../../core/widgets/dialogues/strategy_creation_options_sheet.dart';
import 'package:ballchart/core/repositories/development_repository.dart';

import '../../management/viewmodel/academy_provider.dart';
import '../../player_development/view/my_development_screen.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../viewmodel/strategy_viewmodel.dart';
import 'strategy_detail_screen.dart';

class StrategyScreen extends StatefulWidget {
  const StrategyScreen({super.key});

  @override
  State<StrategyScreen> createState() => _StrategyScreenState();
}

enum _StrategyMediaFilter { all, video, nonVideo }

class _StrategyScreenState extends State<StrategyScreen> {
  _StrategyMediaFilter _mediaFilter = _StrategyMediaFilter.all;
  StrategyViewmodel? _strategyViewmodel;
  int? _formationKpi;
  int? _drillKpi;

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF201F1F);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithRetry();
    });
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final vm = context.read<StrategyViewmodel>();
        _strategyViewmodel = vm;
        await vm.loadStrategies();
        if (vm.errorMessage != null && vm.strategies.isEmpty) {
          throw Exception(vm.errorMessage);
        }
        vm.startLiveSync(); // Start real-time updates
        
        final profileVm = context.read<ProfileViewmodel>();
        if (profileVm.user == null) {
          await profileVm.loadProfile(forceRefresh: true);
        }
        final isPlayer = (profileVm.user?.role ?? '').toLowerCase() == 'player';
        if (isPlayer) {
          await context.read<AcademyProvider>().loadPlayerDashboard(force: true);
        }
        await _loadStrategyKpis();
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load strategies: ${e.toString().replaceAll('Exception: ', '')}'),
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

  Future<void> _loadStrategyKpis() async {
    try {
      final cat = await DevelopmentRepository().fetchCatalog();
      if (!mounted) return;
      setState(() {
        _formationKpi = cat.formationEngagementPct;
        _drillKpi = cat.drillCompletionPct;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _formationKpi = null;
          _drillKpi = null;
        });
      }
    }
  }

  String _pctLabel(int? v) => v == null ? '—' : '$v%';

  bool get _isPlayerUser =>
      (context.read<ProfileViewmodel>().user?.role ?? '').toLowerCase() == 'player';

  @override
  void dispose() {
    _strategyViewmodel?.stopLiveSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Consumer<StrategyViewmodel>(
            builder: (context, vm, _) {
              // Show loading state
              if (vm.isLoading && vm.strategies.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      SizedBox(height: 16),
                      Text('Loading Strategies...', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                );
              }

              // Show error state
              if (vm.errorMessage != null && vm.strategies.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Strategies',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vm.errorMessage!,
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildMediaFilterRow(),
                  const SizedBox(height: 24),
                  const Text('TACTICAL REELS', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  _buildTacticalReels(vm),
                  const SizedBox(height: 32),
                  _buildFormationAnalytics(),
                  if (_formationKpi == null && _drillKpi == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'KPI targets are set by your coach — they will appear above when available.',
                        style: TextStyle(color: outlineColor.withValues(alpha: 0.85), fontSize: 11, height: 1.35),
                      ),
                    ),
                  const SizedBox(height: 32),
                  const Text('ACTIVE PLAYBOOK', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                  const SizedBox(height: 16),
                  ..._buildPlaybookItems(vm),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AcademyProvider>(
      builder: (context, academy, _) {
        final canCreate = academy.hasPermission('createStrategy');
        final isPlayer = (context.watch<ProfileViewmodel>().user?.role ?? '').toLowerCase() == 'player';

        return Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLAYBOOK INTELLIGENCE', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  SizedBox(height: 4),
                  Text('TACTICAL STRATEGY', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
                ],
              ),
            ),
            if (isPlayer)
              IconButton(
                tooltip: 'Training & development',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const MyDevelopmentScreen()),
                  );
                },
                icon: const Icon(Icons.fitness_center, color: primaryColor, size: 26),
              ),
            if (canCreate && !isPlayer)
              GestureDetector(
                onTap: () => _openStrategyCreationFlow(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.black, size: 24),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _strategyHasVideo(StrategyModel s) => s.videoUrl.trim().isNotEmpty;

  String _normalizedVideoUrl(String raw) {
    final resolved = ApiService.resolveMediaUrl(raw).trim();
    if (resolved.isEmpty) return '';
    final uri = Uri.tryParse(resolved);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) return '';
    return uri.toString();
  }

  bool _isLikelyUnsupportedPageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('facebook.com') ||
        host.contains('instagram.com') ||
        host.contains('tiktok.com');
  }

  String? _extractYoutubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final segs = uri.pathSegments;
      if (segs.isNotEmpty && segs.first.trim().isNotEmpty) return segs.first.trim();
    }
    if (host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.trim().isNotEmpty) return v.trim();
      final segs = uri.pathSegments;
      final idx = segs.indexOf('embed');
      if (idx != -1 && idx + 1 < segs.length && segs[idx + 1].trim().isNotEmpty) {
        return segs[idx + 1].trim();
      }
      final shortsIdx = segs.indexOf('shorts');
      if (shortsIdx != -1 && shortsIdx + 1 < segs.length && segs[shortsIdx + 1].trim().isNotEmpty) {
        return segs[shortsIdx + 1].trim();
      }
    }
    return null;
  }

  List<StrategyModel> _visibleStrategies(StrategyViewmodel vm) {
    var list = vm.strategies;
    final profileVm = context.read<ProfileViewmodel>();
    final isPlayer = (profileVm.user?.role ?? '').toLowerCase() == 'player';

    if (isPlayer) {
      final playerId = (profileVm.user?.id ?? '').trim();
      final academy = context.read<AcademyProvider>();
      final teamIds = <String>{};

      final dashboardTeams = academy.playerDashboard?['teams'];
      if (dashboardTeams is List) {
        for (final t in dashboardTeams) {
          if (t is! Map) continue;
          final id = (t['_id'] ?? t['id'] ?? '').toString().trim();
          if (id.isNotEmpty) teamIds.add(id);
        }
      }

      final playerData = academy.playerDashboard?['player'];
      if (playerData is Map) {
        final directTeamId = (playerData['teamId'] ?? playerData['team']?['_id'] ?? '').toString().trim();
        if (directTeamId.isNotEmpty) teamIds.add(directTeamId);
      }

      for (final team in academy.academy.teams) {
        final hasPlayer = team.players.any((p) => p.id == playerId || p.email == profileVm.user?.email);
        if (hasPlayer && team.id.trim().isNotEmpty) {
          teamIds.add(team.id.trim());
        }
      }

      list = list.where((s) {
        final meta = s.metadata ?? const <String, dynamic>{};
        final assignedPlayerId = (meta['assignedPlayerId'] ?? '').toString().trim();
        final assignedTeamId = (meta['assignedTeamId'] ?? '').toString().trim();

        // Global strategy (not assigned to specific player/team).
        if (assignedPlayerId.isEmpty && assignedTeamId.isEmpty) return true;
        // Player assignment has priority.
        if (assignedPlayerId.isNotEmpty) return assignedPlayerId == playerId;
        // Team assignment fallback.
        return assignedTeamId.isNotEmpty && teamIds.contains(assignedTeamId);
      }).toList();
    }

    switch (_mediaFilter) {
      case _StrategyMediaFilter.all:
        return list;
      case _StrategyMediaFilter.video:
        return list.where(_strategyHasVideo).toList();
      case _StrategyMediaFilter.nonVideo:
        return list.where((s) => !_strategyHasVideo(s)).toList();
    }
  }

  Widget _buildMediaFilterRow() {
    Widget chip(String label, _StrategyMediaFilter value) {
      final selected = _mediaFilter == value;
      return GestureDetector(
        onTap: () => setState(() => _mediaFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primaryColor.withOpacity(0.2) : surfaceHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? primaryColor : outlineColor.withOpacity(0.25)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? primaryColor : outlineColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('ALL', _StrategyMediaFilter.all),
        const SizedBox(width: 8),
        chip('VIDEO', _StrategyMediaFilter.video),
        const SizedBox(width: 8),
        chip('NO VIDEO', _StrategyMediaFilter.nonVideo),
      ],
    );
  }

  Widget _buildTacticalReels(StrategyViewmodel vm) {
    if (vm.isLoading && vm.strategies.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: primaryColor)));
    }
    final strategies = _visibleStrategies(vm);
    if (strategies.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(24), border: Border.all(color: outlineColor.withOpacity(0.1), style: BorderStyle.solid)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, color: outlineColor, size: 32),
            const SizedBox(height: 12),
            Text(
              vm.strategies.isEmpty ? 'NO REELS UPLOADED' : 'NO STRATEGIES FOR THIS FILTER',
              style: const TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: strategies.length,
        itemBuilder: (context, index) => _reelCard(strategies[index]),
      ),
    );
  }

  Widget _reelCard(StrategyModel strategy) {
    final thumb = ApiService.resolveMediaUrl(strategy.thumbnailUrl);
    final hasPlayableVideo = _strategyHasVideo(strategy);
    final hasThumb = thumb.trim().isNotEmpty;
    final resolvedVideo = _normalizedVideoUrl(strategy.videoUrl);
    final youtubeId = _extractYoutubeId(resolvedVideo);
    final canPlayNetwork =
        resolvedVideo.isNotEmpty && (youtubeId != null || !_isLikelyUnsupportedPageUrl(resolvedVideo));
    final meta = strategy.metadata ?? const <String, dynamic>{};
    final hasAssignment = (meta['assignedTeamId'] ?? '').toString().trim().isNotEmpty ||
        (meta['assignedPlayerId'] ?? '').toString().trim().isNotEmpty;
    final showAssignedBadge = _isPlayerUser && hasAssignment;

    return GestureDetector(
      onTap: () => _openStrategyDetailsPage(strategy),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [surfaceHigh, surfaceHigh.withOpacity(0.85), bgColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: hasThumb
              ? DecorationImage(
                  image: NetworkImage(thumb),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.45), BlendMode.darken),
                )
              : null,
        ),
        child: Stack(
          children: [
            if (hasPlayableVideo)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(8)),
                  child: const Text('VIDEO', style: TextStyle(color: primaryColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            if (!hasPlayableVideo && !hasThumb)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                  ),
                  child: const Text(
                    'SAVED',
                    style: TextStyle(color: primaryColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strategy.title.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(BasketballStrategy.categoryLabel(strategy.category).toUpperCase(), style: const TextStyle(color: primaryColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  if (showAssignedBadge) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                      ),
                      child: const Text(
                        'FOR YOU',
                        style: TextStyle(color: primaryColor, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasPlayableVideo && canPlayNetwork)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: primaryColor, size: 24),
                ),
              )
            else if (!hasPlayableVideo)
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [primaryColor.withValues(alpha: 0.95), primaryColor.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.sports_basketball, color: Colors.black, size: 28),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationAnalytics() {
    return Row(
      children: [
        Expanded(
          child: _analyticsCard(
            'SET RECOGNITION',
            _pctLabel(_formationKpi),
            Icons.insights,
            const Color(0xFF28D8FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _analyticsCard(
            'DRILL COMPLETION',
            _pctLabel(_drillKpi),
            Icons.check_circle,
            primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _analyticsCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  List<Widget> _buildPlaybookItems(StrategyViewmodel vm) {
    final items = _visibleStrategies(vm);
    if (items.isEmpty) {
      return [
        Text(
          vm.strategies.isEmpty ? 'No plays in playbook.' : 'Nothing matches this filter.',
          style: const TextStyle(color: outlineColor),
        ),
      ];
    }
    return items.map((s) => _playbookItem(s)).toList();
  }

  Widget _playbookItem(StrategyModel s) {
    final hasVideo = _strategyHasVideo(s);
    final subtitle = '${BasketballStrategy.categoryLabel(s.category).toUpperCase()} • ${s.sourceType.toUpperCase()}'
        '${hasVideo ? ' • VIDEO' : ''}';
    final meta = s.metadata ?? const <String, dynamic>{};
    final hasAssignment = (meta['assignedTeamId'] ?? '').toString().trim().isNotEmpty ||
        (meta['assignedPlayerId'] ?? '').toString().trim().isNotEmpty;
    final showPlayerBadge = _isPlayerUser && hasAssignment;

    return GestureDetector(
      onTap: () => _openStrategyDetailsPage(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B1B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasVideo ? primaryColor.withOpacity(0.35) : outlineColor.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: hasVideo ? primaryColor.withValues(alpha: 0.14) : surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasVideo ? primaryColor.withValues(alpha: 0.4) : outlineColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      hasVideo ? Icons.play_lesson_outlined : Icons.sports_basketball_outlined,
                      color: hasVideo ? primaryColor : outlineColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
                        if (showPlayerBadge) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                            ),
                            child: const Text(
                              'ASSIGNED TO YOU',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(hasVideo ? Icons.play_circle_outline : Icons.chevron_right, color: outlineColor, size: 22),
          ],
        ),
      ),
    );
  }
  void _openStrategyDetailsPage(StrategyModel s) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StrategyDetailScreen(strategy: s),
      ),
    );
  }

  Future<void> _openStrategyCreationFlow(BuildContext context) async {
    final vm = context.read<StrategyViewmodel>();
    final entry = await showStrategyCreationOptionsSheet(context);
    if (!context.mounted || entry == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => CreateStrategyDialog(
        entry: entry,
        onStrategyCreated:
            (title, description, category, sourceTypeForApi, plays, imagePath, videoUrl, tags, referenceUrl) async {
          try {
            await vm.createStrategy(
                  title: title,
                  category: category,
                  sourceType: sourceTypeForApi,
                  sourceText: description,
                  videoUrl: (videoUrl ?? '').trim().isEmpty ? null : videoUrl!.trim(),
                  tags: tags,
                  metadata: {
                    'playSteps': plays,
                    'revisionState': 'draft',
                    'creationEntry': entry.name,
                    if (referenceUrl != null && referenceUrl.trim().isNotEmpty) 'referenceUrl': referenceUrl.trim(),
                    if (imagePath != null && imagePath.isNotEmpty) 'localDiagramPath': imagePath,
                  },
                );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Strategy created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create strategy: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

}



