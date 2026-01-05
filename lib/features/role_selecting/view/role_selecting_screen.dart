import 'package:flutter/material.dart';
import 'package:hoopstar/core/widgets/feature_card_selectingrole.dart';
import 'package:hoopstar/features/role_selecting/viewmodel/roleselecting_viewmodel.dart';

import '../../../core/widgets/custom_button.dart';

enum UserRole { none, coach, player }

class RoleSelectingScreen extends StatefulWidget {
  const RoleSelectingScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectingScreen> createState() => _RoleSelectingScreenState();
}

class _RoleSelectingScreenState extends State<RoleSelectingScreen> {
  UserRole selectedRole = UserRole.none;

  Color get selectedColor {
    switch (selectedRole) {
      case UserRole.coach:
        return const Color(0xFFF59E0B); // Yellow
      case UserRole.player:
        return const Color(0xFF3B82F6); // Blue
      default:
        return const Color(0xFFF59E0B); // Yellow
    }
  }

  bool get canContinue => selectedRole != UserRole.none;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Title
              const Text(
                'Choose Your Role',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Select how you want to use HoopStar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),

              const SizedBox(height: 40),

              // Coach Card
              FeatureCardSelectingrole(
                icon: Icons.assignment,
                title: 'Coach',
                subtitle: 'Manage teams, create training plans, and track player progress',
                iconColor: const Color(0xFFF59E0B),
                isSelected: selectedRole == UserRole.coach,
                onTap: () {
                  setState(() {
                    selectedRole = UserRole.coach;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Player Card
              FeatureCardSelectingrole(
                icon: Icons.flash_on,
                title: 'Player',
                subtitle: 'Join teams, complete training battles, and climb the leaderboard',
                iconColor: const Color(0xFF3B82F6),
                isSelected: selectedRole == UserRole.player,
                onTap: () {
                  setState(() {
                    selectedRole = UserRole.player;
                  });
                },
              ),

              const Spacer(),

              // Continue Button
              CustomButton(
                text: 'Continue',
                backgroundColor: selectedColor,
                textColor: canContinue ?
                (selectedRole == UserRole.coach ? Colors.black : Colors.white) :
                Colors.black,
                onPressed: canContinue ? () {
                  // Handle navigation
                  print('Selected role: ${selectedRole.name}');
                  // Navigator.push(...) or other navigation logic
                  RoleselectingViewmodel.goToAuth(context);
                } : () {},
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
