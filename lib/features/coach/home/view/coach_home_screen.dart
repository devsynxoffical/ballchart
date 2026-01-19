import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/dialogues/CreateTeamDialog.dart';
import '../../../../core/widgets/home/header.dart';
import '../../../../core/widgets/home/invite_players_card.dart';
import '../../../../core/widgets/home/stats_row.dart';
import '../../../../core/widgets/home/team_card.dart';

import 'package:provider/provider.dart';
import '../../../profile/viewmodel/profile_viewmodel.dart';
import '../../../../features/auth/viewmodel/auth_viewmodel.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileViewModel = context.read<ProfileViewmodel>();
      if (profileViewModel.user == null) {
        profileViewModel.loadProfile();
      }
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
            child: Consumer<ProfileViewmodel>(
              builder: (context, viewModel, child) {
                final user = viewModel.user;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Logout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Header(),
                        Consumer<AuthViewmodel>(
                          builder: (context, authVm, child) {
                            return IconButton(
                              icon: const Icon(Icons.logout, color: Colors.white),
                              onPressed: () => authVm.logout(context),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    user != null 
                        ? StatsRow(user: user)
                        : const Center(child: CircularProgressIndicator()),
            
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
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (_) => const CreateTeamDialog(),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    InvitePlayersCard(),
                  ],
                );    
              },
            ),
          ),
        ),
      ),
    );
  }
}
