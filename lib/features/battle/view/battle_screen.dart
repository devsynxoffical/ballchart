import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/battle_viewmodel.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/hoopstar_bottom_nav.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/battle/battle_header.dart';
import '../../../core/widgets/battle/leader_board_Header.dart';
import '../../../core/widgets/battle/rank_progress_card.dart';
import '../../../core/widgets/battle/task_card.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  int _navIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BattleViewmodel>().loadBattles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BattleHeader(),
                const SizedBox(height: 20),
                const RankProgressCard(),
                const SizedBox(height: 28),
                
                // Header for Battles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Battles',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.yellow),
                      onPressed: () {
                         // Quick hack to create battle for demo
                         context.read<BattleViewmodel>().createBattle('Court A', DateTime.now().add(const Duration(hours: 1)));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Battles List
                Consumer<BattleViewmodel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (viewModel.battles.isEmpty) {
                      return const Text('No active battles', style: TextStyle(color: Colors.white60));
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: viewModel.battles.length,
                      itemBuilder: (context, index) {
                        final battle = viewModel.battles[index];
                        return Card(
                          color: const Color(0xFF1E293B),
                          child: ListTile(
                            title: Text('Battle at ${battle.location}', style: const TextStyle(color: Colors.white)),
                            subtitle: Text(battle.status, style: const TextStyle(color: Colors.white60)),
                            trailing: ElevatedButton(
                              onPressed: () {
                                viewModel.joinBattle(battle.id);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow),
                              child: const Text('Join', style: TextStyle(color: Colors.black)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 30),
                LeaderboardHeader(),
                const SizedBox(height: 16),
                const LeaderboardItem(
                  rank: 1,
                  name: 'Alex Johnson',
                  role: 'Captain',
                  points: 485,
                  progress: 0.95,
                  color: AppColors.yellow,
                ),
                const SizedBox(height: 14),
                const LeaderboardItem(
                  rank: 2,
                  name: 'You',
                  role: 'All-Star',
                  points: 375,
                  progress: 0.75,
                  color: Colors.pinkAccent,
                  isYou: true,
                ),
                const SizedBox(height: 14),
                const LeaderboardItem(
                  rank: 3,
                  name: 'Sarah Williams',
                  role: 'Starter',
                  points: 340,
                  progress: 0.65,
                  color: Colors.lightBlue,
                ),
                const SizedBox(height: 14),
                const LeaderboardItem(
                  rank: 4,
                  name: 'Mike Chen',
                  role: 'Starter',
                  points: 280,
                  progress: 0.55,
                  color: Colors.cyan,
                ),
                const SizedBox(height: 14),
                const LeaderboardItem(
                  rank: 5,
                  name: 'Emma Davis',
                  role: 'Rookie',
                  points: 195,
                  progress: 0.35,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
