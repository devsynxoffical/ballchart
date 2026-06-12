import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ballchart/core/models/battle_model.dart';
import 'package:ballchart/features/battle/viewmodel/battle_viewmodel.dart';
import 'package:ballchart/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:ballchart/features/tactics/view/tactical_lab_screen.dart';

/// Game hub + play-by-play for one scheduled game (join, roster, tactical lab).
Future<void> showBattleHubBottomSheet(
  BuildContext context, {
  required BattleModel battle,
  required BattleViewmodel battleVm,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C1B1B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.88,
      child: DefaultTabController(
        length: 2,
        child: _BattleHubContent(
          battle: battle,
          battleVm: battleVm,
        ),
      ),
    ),
  );
}

class _BattleHubContent extends StatelessWidget {
  const _BattleHubContent({
    required this.battle,
    required this.battleVm,
  });

  final BattleModel battle;
  final BattleViewmodel battleVm;

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color outlineColor = Color(0xFF9D8F79);

  String _when(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewmodel>().user;
    final isHost = (user?.id ?? '') == battle.hostId;
    final canJoin = battle.canJoin && !battle.isFull && battle.isPending;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(color: outlineColor.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(4)),
        ),
        TabBar(
          labelColor: primaryColor,
          unselectedLabelColor: outlineColor,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'GAME HUB'),
            Tab(text: 'PLAY-BY-PLAY'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _commandTab(context, isHost, canJoin),
              _playByPlayTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _commandTab(BuildContext context, bool isHost, bool canJoin) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Text(
          battle.displayTitle.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
        ),
        const SizedBox(height: 6),
        Text(
          _when(battle.dateTime),
          style: TextStyle(color: outlineColor.withValues(alpha: 0.95), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(battle.statusDisplayLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              backgroundColor: primaryColor.withValues(alpha: 0.15),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
            ),
            Chip(
              label: Text('${battle.participantCount}/${battle.maxParticipants} rostered', style: const TextStyle(fontSize: 11)),
              backgroundColor: Colors.white12,
            ),
            if (battle.isJoined)
              const Chip(
                label: Text('You are in', style: TextStyle(fontSize: 11, color: Colors.lightGreenAccent)),
                backgroundColor: Colors.black26,
              ),
          ],
        ),
        if (battle.description != null && battle.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(battle.description!, style: TextStyle(color: outlineColor.withValues(alpha: 0.95), fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 20),
        const Text('ROSTER', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        ...battle.participants.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor.withValues(alpha: 0.2),
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      Text(p.role.toUpperCase(), style: TextStyle(color: outlineColor.withValues(alpha: 0.8), fontSize: 10)),
                    ],
                  ),
                ),
                if (p.id == battle.hostId)
                  Text('HOST', style: TextStyle(color: primaryColor.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        if (battle.participants.isEmpty)
          Text('No participants yet.', style: TextStyle(color: outlineColor.withValues(alpha: 0.8))),
        const SizedBox(height: 24),
        if (canJoin && !battle.isJoined)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              await battleVm.joinBattle(battle.id);
              if (context.mounted) {
                final err = battleVm.errorMessage;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.redAccent));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined battle')));
                  Navigator.pop(context);
                }
              }
            },
            icon: const Icon(Icons.how_to_reg),
            label: const Text('JOIN THIS GAME', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        if (battle.isJoined && battle.isPending)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Leave game will be available in a future update.')),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Leave (coming soon)'),
          ),
        if (isHost && battle.isPending) ...[
          const SizedBox(height: 12),
          Text(
            'Host: start the session from the server when your roster is ready. (Start API wiring can be added next.)',
            style: TextStyle(color: outlineColor.withValues(alpha: 0.85), fontSize: 11),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: outlineColor.withValues(alpha: 0.4)),
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TacticalLabScreen(battleId: battle.id),
              ),
            );
          },
          icon: const Icon(Icons.grid_4x4_outlined),
          label: const Text('Open tactical lab (this battle)'),
        ),
      ],
    );
  }

  Widget _playByPlayTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        const Text(
          'LIVE FEED',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'),
        ),
        const SizedBox(height: 8),
        Text(
          'Play-by-play events (scores, fouls, key moments) will stream here when the game is live and logging is enabled.',
          style: TextStyle(color: outlineColor.withValues(alpha: 0.95), fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: 24),
        _fakeEvent('Scheduled', battle.statusDisplayLabel, _when(battle.dateTime)),
        if (battle.isOngoing || battle.isPausedSession)
          _fakeEvent('Session', battle.isPausedSession ? 'Paused' : 'In progress', '—'),
        if (battle.isFinished && battle.result != null && battle.result!.isNotEmpty)
          _fakeEvent('Result', battle.result!, 'Final'),
        const SizedBox(height: 24),
        Text(
          'Tip: use Game Hub → Join, then open Tactical Lab to rehearse plays for this matchup.',
          style: TextStyle(color: outlineColor.withValues(alpha: 0.75), fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _fakeEvent(String title, String body, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(color: outlineColor.withValues(alpha: 0.8), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
