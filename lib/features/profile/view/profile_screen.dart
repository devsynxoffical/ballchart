import 'package:flutter/material.dart';
import '../../../core/widgets/battle/rank_progress_card.dart';
import '../../../core/widgets/home/stats_row.dart';
import '../../../core/widgets/profile/AchievementsSection/achievements_section.dart';
import '../../../core/widgets/profile/MyTeamsSection/my_teams_section.dart';
import '../../../core/widgets/profile/SettingsSection/settings_section.dart';
import '../../../core/widgets/profile/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _navIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const ProfileHeader(),
              const SizedBox(height: 20),
              StatsRow(),
              const SizedBox(height: 20),
              const RankProgressCard(),
              const SizedBox(height: 24),
              const AchievementsSection(),
              const SizedBox(height: 24),
              const MyTeamsSection(),
              const SizedBox(height: 24),
              const SettingsSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
