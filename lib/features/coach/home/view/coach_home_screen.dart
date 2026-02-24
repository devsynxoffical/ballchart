import 'package:flutter/material.dart';
import '../../../../core/widgets/home/header.dart';

import 'package:provider/provider.dart';
import '../../../profile/viewmodel/profile_viewmodel.dart';
import 'widgets/teams_tab.dart';

class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ProfileViewmodel>();

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: const Header(),
      ),
      body: const TeamsTab(),
    );
  }
}
