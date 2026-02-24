import 'package:flutter/material.dart';
import 'package:courtiq/core/widgets/custom_button.dart';
import 'package:courtiq/core/widgets/dialogues/CreateTeamDialog.dart';
import 'package:courtiq/core/widgets/home/invite_players_card.dart';
import 'package:courtiq/core/widgets/home/team_card.dart';
import 'package:courtiq/features/coach/team_details/view/team_detail_screen.dart';

class TeamsTab extends StatefulWidget {
  const TeamsTab({super.key});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  // Mock data for teams
  final List<Map<String, dynamic>> _teams = [
    {
      'name': 'Thunder Squad',
      'members': '12 members',
      'icon': Icons.flash_on,
      'color': Colors.orange,
    },
    {
      'name': 'Rising Stars',
      'members': '8 members',
      'icon': Icons.star,
      'color': Colors.blueAccent,
    },
    {
      'name': 'Elite Dunkers',
      'members': '15 members',
      'icon': Icons.sports_basketball,
      'color': Colors.amber,
    },
  ];

  void _addNewTeam(Map<String, dynamic> newTeam) {
    setState(() {
      _teams.add(newTeam);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._teams.map((team) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamDetailScreen(teamName: team['name']),
                  ),
                );
              },
              child: TeamCard(
                title: team['name'],
                members: team['members'],
                icon: team['icon'],
                iconBg: team['color'],
              ),
            ),
          )).toList(),
          
          const SizedBox(height: 10),
          CustomButton(
            text: '+ Create New Team',
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => CreateTeamDialog(
                  onTeamCreated: (name, age, color) {
                    _addNewTeam({
                      'name': name,
                      'members': '1 member', // Coach
                      'icon': Icons.shield,
                      'color': color,
                    });
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          InvitePlayersCard(),
        ],
      ),
    );
  }
}
