import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../core/widgets/home/header.dart';
import '../../../core/widgets/hoopstar_bottom_nav.dart';
import '../../../core/widgets/home/invite_players_card.dart';
import '../../../core/widgets/home/stats_row.dart';
import '../../../core/widgets/home/team_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int _currentIndex = 0;
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Header(),
              
                  const SizedBox(height: 20),
              
                  StatsRow(),
              
                  const SizedBox(height: 24),
              
                  TeamCard(
                    title: 'Thunder Squad',
                    members: '12 members',
                    icon: Icons.flash_on,
                    iconBg: Colors.orange,
                  ),
              
                  const SizedBox(height: 14),
              
                  TeamCard(
                    title: 'Rising Stars',
                    members: '8 members',
                    icon: Icons.star,
                    iconBg: Colors.blueAccent,
                  ),
              
                  const SizedBox(height: 14),
              
                  TeamCard(
                    title: 'Elite Dunkers',
                    members: '15 members',
                    icon: Icons.sports_basketball,
                    iconBg: Colors.amber,
                  ),
              
                  const SizedBox(height: 24),
              
                  CustomButton(
                    text: '+ Create New Team',
                    onPressed: () {},
                  ),
              
                  const SizedBox(height: 20),
              
                  InvitePlayersCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
