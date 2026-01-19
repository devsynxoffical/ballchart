import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/profile_viewmodel.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/battle/rank_progress_card.dart';
import '../../../core/widgets/home/stats_row.dart';
import '../../../core/widgets/profile/AchievementsSection/achievements_section.dart';
import '../../../core/widgets/profile/MyTeamsSection/my_teams_section.dart';
import '../../../core/widgets/profile/SettingsSection/settings_section.dart';
import '../../../core/widgets/profile/profile_header.dart';
import '../../../core/widgets/profile/profile_info_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _navIndex = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewmodel>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Consumer<ProfileViewmodel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (viewModel.user == null) {
                return const Center(child: Text('Failed to load profile', style: TextStyle(color: Colors.white)));
              }
              
              final user = viewModel.user!;
              
              return Column(
                children: [
                   ProfileHeader(user: user),
                  const SizedBox(height: 20),
                   StatsRow(user: user),
                  const SizedBox(height: 20),
                  ProfileInfoSection(user: user),
                  const SizedBox(height: 24),
                  RankProgressCard(user: user),
                  const SizedBox(height: 24),
                  const AchievementsSection(),
                  const SizedBox(height: 24),
                  const MyTeamsSection(),
                  const SizedBox(height: 24),
                  const SettingsSection(),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
