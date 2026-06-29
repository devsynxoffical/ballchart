import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/battle_viewmodel.dart';
import '../../../core/models/battle_model.dart';
import '../../../core/models/tactical/tactical_schema.dart';
import '../../../core/widgets/dialogues/create_battle_sheet.dart';
import '../../management/viewmodel/academy_provider.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../../tactics/view/tactical_lab_screen.dart';
import '../widgets/battle_hub_sheet.dart';

enum _BattleListFilter { all, scheduled, live, paused, finished }

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  BattleViewmodel? _battleViewmodel;
  _BattleListFilter _battleFilter = _BattleListFilter.all;
  
  static const Color primaryColor = Color(0xFFFFD900); // FDB927 equivalent
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF2A2A2A); // matching the surface-container-high
  static const Color surfaceContainer = Color(0xFF201F1F);
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
        final battleViewModel = context.read<BattleViewmodel>();
        _battleViewmodel = battleViewModel;
        await battleViewModel.loadBattles();
        battleViewModel.startLiveUpdates(); // Start real-time updates
        
        final profileViewModel = context.read<ProfileViewmodel>();
        if (profileViewModel.user == null) {
          await profileViewModel.loadProfile(forceRefresh: true);
        }
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load games: ${e.toString().replaceAll('Exception: ', '')}'),
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
  void dispose() {
    _battleViewmodel?.stopLiveUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final battleVm = context.watch<BattleViewmodel>();
    final academyVm = context.watch<AcademyProvider>();

    // Show loading state
    if (battleVm.isLoading && battleVm.battles.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text('Loading games...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (battleVm.errorMessage != null && battleVm.battles.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Games',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  battleVm.errorMessage!,
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: academyVm.hasPermission('createBattle')
          ? FloatingActionButton(
              heroTag: 'battle_fab',
              backgroundColor: primaryColor,
              onPressed: () => showCreateBattleSheet(
                    context,
                    scaffoldMessenger: ScaffoldMessenger.of(context),
                  ),
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'OPERATIONS',
                    style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  IconButton(
                    tooltip: 'Tactical lab — voice & court animation',
                    onPressed: () {
                      final id = _featuredBattle(battleVm.battles)?.id;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TacticalLabScreen(battleId: id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.developer_board, color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildLiveBattleHero(battleVm, onOpenHub: (b) => _openBattleHub(battleVm, b)),
              const SizedBox(height: 32),
              _buildExecutionTimelinePlaceholder(),
              const SizedBox(height: 40),
              _buildBattleRepository(battleVm),
              const SizedBox(height: 40),
              _buildStrategicProfiles(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  BattleModel? _featuredBattle(List<BattleModel> battles) {
    BattleModel? live;
    for (final b in battles) {
      if (b.isOngoing && !b.isPausedSession) {
        live = b;
        break;
      }
    }
    if (live != null) return live;
    final pending = battles.where((b) => b.isPending).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return pending.isNotEmpty ? pending.first : (battles.isNotEmpty ? battles.first : null);
  }

  void _openBattleHub(BattleViewmodel vm, BattleModel b) {
    showBattleHubBottomSheet(context, battle: b, battleVm: vm);
  }

  String _formatBattleWhen(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  List<BattleModel> _filteredBattles(BattleViewmodel vm) {
    final list = vm.battles;
    switch (_battleFilter) {
      case _BattleListFilter.all:
        return list;
      case _BattleListFilter.scheduled:
        return list.where((b) => b.sessionPhase == BattleSessionPhase.scheduled).toList();
      case _BattleListFilter.live:
        return list.where((b) => b.sessionPhase == BattleSessionPhase.live).toList();
      case _BattleListFilter.paused:
        return list.where((b) => b.isPausedSession).toList();
      case _BattleListFilter.finished:
        return list.where((b) => b.sessionPhase == BattleSessionPhase.finished).toList();
    }
  }

  Widget _buildLiveBattleHero(BattleViewmodel vm, {required void Function(BattleModel) onOpenHub}) {
    final featured = _featuredBattle(vm.battles);
    if (featured == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: surfaceHigh,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: outlineColor.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GAME CENTER', style: TextStyle(color: primaryColor.withOpacity(0.85), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            const SizedBox(height: 8),
            const Text('No games yet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
            const SizedBox(height: 8),
            Text(
              'Schedule a match with + to see live status and execution here.',
              style: TextStyle(color: outlineColor.withOpacity(0.9), fontSize: 12, height: 1.4),
            ),
          ],
        ),
      );
    }

    final phase = featured.sessionPhase;
    final isLive = phase == BattleSessionPhase.live;
    final isPaused = featured.isPausedSession;
    final leftName = featured.hostName.isNotEmpty ? featured.hostName : 'HOST';
    final rightName = featured.participants.isNotEmpty
        ? featured.participants.first.name
        : (featured.maxParticipants > 1 ? 'OPPONENT TBD' : 'OPEN');

    final badgeColor = isPaused
        ? const Color(0xFF6B5B00)
        : isLive
            ? const Color(0xFF93000A)
            : featured.isFinished
                ? const Color(0xFF1B5E20)
                : const Color(0xFF1565C0);
    final badgeTextColor = isPaused ? primaryColor : (isLive ? const Color(0xFFFFDAD6) : Colors.white70);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.2), bgColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  featured.isPending ? 'NEXT UP' : (isLive || isPaused ? 'ACTIVE GAME' : 'GAME'),
                  style: TextStyle(color: primaryColor.withOpacity(0.95), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                ),
                const SizedBox(height: 4),
                Text(
                  featured.displayTitle.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        featured.statusDisplayLabel,
                        style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatBattleWhen(featured.dateTime).toUpperCase(),
                        style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        leftName.toUpperCase(),
                        style: const TextStyle(color: outlineColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rightName.toUpperCase(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: outlineColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    featured.isFinished && featured.result != null && featured.result!.trim().isNotEmpty
                        ? featured.result!
                        : (isLive || isPaused
                            ? (isPaused ? 'PAUSED' : 'MATCH IN PROGRESS')
                            : 'SCHEDULED'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isLive ? primaryColor : Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Space Grotesk',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (featured.description != null && featured.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(featured.description!, style: TextStyle(color: outlineColor.withOpacity(0.95), fontSize: 12, height: 1.35)),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [primaryColor, Color(0xFFFFDCA3)]),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => onOpenHub(featured),
                          child: const Text('GAME HUB', style: TextStyle(color: Color(0xFF422D00), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: outlineColor.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () => onOpenHub(featured),
                        child: const Text('PLAY-BY-PLAY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionTimelinePlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: primaryColor.withOpacity(0.9), size: 22),
              const SizedBox(width: 10),
              const Text('EXECUTION TIMELINE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Phase 3: load strategy steps, log events (assist, turnover, shot), and diff expected vs actual.',
            style: TextStyle(color: outlineColor.withOpacity(0.95), fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                    child: Text('${i + 1}', style: const TextStyle(color: outlineColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: outlineColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBattleFilterRow() {
    Widget chip(String label, _BattleListFilter value) {
      final selected = _battleFilter == value;
      return GestureDetector(
        onTap: () => setState(() => _battleFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? primaryColor.withOpacity(0.18) : bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? primaryColor : outlineColor.withOpacity(0.2)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? primaryColor : outlineColor,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('ALL', _BattleListFilter.all),
          const SizedBox(width: 8),
          chip('SCHEDULED', _BattleListFilter.scheduled),
          const SizedBox(width: 8),
          chip('LIVE', _BattleListFilter.live),
          const SizedBox(width: 8),
          chip('PAUSED', _BattleListFilter.paused),
          const SizedBox(width: 8),
          chip('FINISHED', _BattleListFilter.finished),
        ],
      ),
    );
  }

  Color _accentForBattle(BattleModel b) {
    if (b.isPausedSession) return const Color(0xFFFFBA29);
    if (b.isOngoing) return primaryColor;
    if (b.isPending) return const Color(0xFF14D7FF);
    if (b.isFinished) return const Color(0xFFFFE16D);
    return outlineColor;
  }

  Widget _buildBattleRepository(BattleViewmodel vm) {
    final rows = _filteredBattles(vm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: primaryColor, width: 4)),
          ),
          padding: const EdgeInsets.only(left: 16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GAME SCHEDULE', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                  SizedBox(height: 4),
                  Text('UPCOMING & PAST GAMES', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                ],
              ),
              Icon(Icons.tune, color: outlineColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildBattleFilterRow(),
        const SizedBox(height: 20),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              vm.battles.isEmpty ? 'No games scheduled.' : 'No games match this filter.',
              style: TextStyle(color: outlineColor.withOpacity(0.9), fontSize: 13),
            ),
          )
        else
          ...rows.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _battleDataRow(b, vm),
              )),
      ],
    );
  }

  Widget _battleDataRow(BattleModel b, BattleViewmodel vm) {
    final accent = _accentForBattle(b);
    final iconText = b.statusDisplayLabel.length > 3 ? b.statusDisplayLabel.substring(0, 3) : b.statusDisplayLabel;
    final loc = b.location.trim();
    final locPart = loc.isNotEmpty ? loc : 'Location TBD';
    final subtitle = '${_formatBattleWhen(b.dateTime)} • $locPart • ${b.battleType.toUpperCase()}';
    final score = b.isFinished && b.result != null && b.result!.isNotEmpty ? b.result : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openBattleHub(vm, b),
        onLongPress: b.isPending
            ? () => showCreateBattleSheet(
                  context,
                  scaffoldMessenger: ScaffoldMessenger.of(context),
                  existing: b,
                )
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(
                      iconText,
                      style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.displayTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle.toUpperCase(),
                        style: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (score != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(score, style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                const SizedBox(height: 4),
                Text(b.statusDisplayLabel, style: TextStyle(color: accent.withOpacity(0.85), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (b.isPending)
                  IconButton(
                    tooltip: 'Edit game',
                    onPressed: () => showCreateBattleSheet(
                      context,
                      scaffoldMessenger: ScaffoldMessenger.of(context),
                      existing: b,
                    ),
                    icon: const Icon(Icons.edit_outlined, color: outlineColor, size: 20),
                  ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: outlineColor.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _openBattleHub(vm, b),
                  child: Text(b.statusDisplayLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ],
            ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildStrategicProfiles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Color(0xFF14D7FF), width: 4)),
          ),
          padding: const EdgeInsets.only(left: 16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STRATEGIC PROFILES', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
              SizedBox(height: 4),
              Text('SCOUTING INTELLIGENCE', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _scoutCardPlayer(),
        const SizedBox(height: 16),
        _scoutCardTeamAnalysis(),
      ],
    );
  }

  Widget _scoutCardPlayer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text('TARGET FOCUS', style: TextStyle(color: Color(0xFFADEBFF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
                 child: const Text('ELITE', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
               ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
             children: [
                Container(
                   width: 50,
                   height: 50,
                   decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                   ),
                   child: const Icon(Icons.person, color: outlineColor, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                   child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text('Marcus "Ghost" Chen', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                      ],
                   ),
                ),
             ],
          ),
          const SizedBox(height: 24),
          Row(
             children: [
                Expanded(child: _scoutStat('PER', '28.4', Colors.white)),
                const SizedBox(width: 8),
                Expanded(child: _scoutStat('DEF', 'A+', const Color(0xFFADEBFF))),
                const SizedBox(width: 8),
                Expanded(child: _scoutStat('STK', '88%', primaryColor)),
             ],
          ),
        ],
      ),
    );
  }

  Widget _scoutStat(String label, String value, Color color) {
    return Container(
       padding: const EdgeInsets.symmetric(vertical: 12),
       decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
       child: Column(
          children: [
             Text(label, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
             const SizedBox(height: 4),
             Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          ],
       ),
    );
  }

  Widget _scoutCardTeamAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Container(
               width: 50,
               height: 50,
               decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
               child: const Icon(Icons.analytics, color: outlineColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
               child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      const Text('TEAM ANALYSIS', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                      const SizedBox(height: 12),
                      const Text('PHANTOMS OFFENSIVE REED', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                      const SizedBox(height: 8),
                      const Text('High tendency for corner three conversion in transition. Strategy: Implement heavy double-screen coverage.', style: TextStyle(color: outlineColor, fontSize: 12, height: 1.4)),
                      const SizedBox(height: 16),
                      Wrap(
                         spacing: 8,
                         children: [
                            _tag('TRANSITION PLAY'),
                            _tag('3PT FOCUS'),
                         ],
                      ),
                  ],
               ),
            ),
         ],
      ),
    );
  }

  Widget _tag(String title) {
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFADEBFF).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(title, style: const TextStyle(color: Color(0xFFADEBFF), fontSize: 9, fontWeight: FontWeight.bold)),
     );
  }

}
