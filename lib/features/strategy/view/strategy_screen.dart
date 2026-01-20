import 'package:flutter/material.dart';

import '../../../core/widgets/strategy/card/strategy_card.dart';
import '../../../core/widgets/strategy/strategy_header.dart';
import '../../../core/widgets/strategy/strategy_tabs.dart';

class StrategyScreen extends StatefulWidget {
  const StrategyScreen({super.key});

  @override
  State<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends State<StrategyScreen> {
  int _navIndex = 2;

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
                StrategyHeader(),
                SizedBox(height: 16),
                StrategyTabs(),
                SizedBox(height: 20),

                // Strategy cards
                StrategyCard(
                  coachName: 'Coach Marcus',
                  role: 'Head Coach',
                  timeAgo: '2 hours ago',
                  title: 'Pick and Roll Setup - High Post',
                  imageType: StrategyMedia.image,
                  mediaDuration: '2:15',
                  likes: 24,
                  comments: 156,
                ),

                SizedBox(height: 20),

                StrategyCard(
                  coachName: 'Coach Sarah',
                  role: 'Assistant Coach',
                  timeAgo: '5 hours ago',
                  title: 'Zone Defense Breakdown - 2-3 Formation',
                  imageType: StrategyMedia.video,
                  mediaDuration: '3:45',
                  likes: 42,
                  comments: 203,
                ),
              ],
            ),
          ),
        ),
      ),

    );
  }
}
