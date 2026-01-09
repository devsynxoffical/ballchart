import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/hoopstar_bottom_nav.dart';
import '../../../core/widgets/battle/battle_header.dart';
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
              children: const [
                BattleHeader(),
                SizedBox(height: 20),
                RankProgressCard(),
                SizedBox(height: 28),
                TasksHeader(),
                SizedBox(height: 16),
                TaskCard(
                  title: '20 Mins Dribbling Practice',
                  duration: '20 min',
                  difficulty: 'medium',
                  points: '+50 pts',
                  difficultyColor: Colors.amber,
                ),
                SizedBox(height: 14),
                TaskCard(
                  title: 'Free Throw Challenge (50 shots)',
                  duration: '15 min',
                  difficulty: 'hard',
                  points: '+75 pts',
                  difficultyColor: Colors.redAccent,
                ),
                SizedBox(height: 14),
                TaskCard(
                  title: 'Defensive Slide Drills',
                  duration: '10 min',
                  difficulty: 'easy',
                  points: '+30 pts',
                  difficultyColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: HoopStarBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}
