import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/hoopstar_bottom_nav.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/battle/battle_header.dart';
import '../../../core/widgets/battle/leader_board_Header.dart';
import '../../../core/widgets/battle/rank_progress_card.dart';
import '../../../core/widgets/battle/task_card.dart';
import '../../../core/widgets/battle/tasks_header.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  int _navIndex = 1;

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
                const TasksHeader(),
                const SizedBox(height: 16),
                const TaskCard(
                  title: '20 Mins Dribbling Practice',
                  duration: '20 min',
                  difficulty: 'medium',
                  points: '+50 pts',
                  difficultyColor: AppColors.yellow,
                ),
                const SizedBox(height: 14),
                const TaskCard(
                  title: 'Free Throw Challenge (50 shots)',
                  duration: '15 min',
                  difficulty: 'hard',
                  points: '+75 pts',
                  difficultyColor: Colors.redAccent,
                ),
                const SizedBox(height: 14),
                const TaskCard(
                  title: 'Defensive Slide Drills',
                  duration: '10 min',
                  difficulty: 'easy',
                  points: '+30 pts',
                  difficultyColor: Colors.green,
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
