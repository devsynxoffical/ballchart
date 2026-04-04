import 'package:flutter/material.dart';
import 'package:courtiq/core/widgets/custom_button.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/onboarding/feature_card.dart';
import '../viewmodel/onboarding_viewmodel.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellow,
                ),
                child: const Center(
                  child: Icon(
                    Icons.sports_basketball,
                    size: 55,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App Name
              const Text(
                'BallChart',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.yellow,
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle
              const Text(
                'Your Ultimate Basketball Community & Training Platform',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),

              const SizedBox(height: 40),

              // Feature cards
              FeatureCard(
                icon: Icons.groups,
                title: 'Team Management',
                subtitle: 'Connect with coaches and players',
                iconColor: AppColors.yellow,
              ),

              const SizedBox(height: 14),

              FeatureCard(
                icon: Icons.flash_on,
                title: 'Training Battles',
                subtitle: 'Compete and level up your skills',
                iconColor: Colors.blueAccent,
              ),

              const SizedBox(height: 14),

              FeatureCard(
                icon: Icons.bar_chart,
                title: 'Track Progress',
                subtitle: 'Rise from Rookie to Captain',
                iconColor: AppColors.yellow,
              ),

              const Spacer(),

              // Get Started Button
              CustomButton(
                text: "Get Started",
                onPressed: () {
                  OnboardingViewModel.goToRoleSelecting(context); // navigate
                },
                backgroundColor: AppColors.yellow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
